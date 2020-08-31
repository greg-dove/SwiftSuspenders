/*
 * Copyright (c) 2012 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.swiftsuspenders.reflection
{

	import org.apache.royale.reflection.describeType;
	import org.apache.royale.reflection.TypeDefinition;
	import org.apache.royale.reflection.MethodDefinition;
	import org.apache.royale.reflection.DefinitionWithMetaData;
	import org.apache.royale.reflection.MemberDefinitionBase;
	import org.apache.royale.reflection.MetaDataDefinition;
	import org.apache.royale.reflection.MetaDataArgDefinition;
	import org.apache.royale.reflection.ParameterDefinition;
	import org.apache.royale.reflection.VariableDefinition;

	import org.apache.royale.reflection.getQualifiedClassName;
	import org.apache.royale.reflection.utils.isDerivedType;
	import org.apache.royale.reflection.utils.getMembersWithMetadata;
	import org.apache.royale.reflection.utils.MemberTypes;

	import org.swiftsuspenders.errors.InjectorError;

	import org.swiftsuspenders.typedescriptions.ConstructorInjectionPoint;
	import org.swiftsuspenders.typedescriptions.MethodInjectionPoint;
	import org.swiftsuspenders.typedescriptions.NoParamsConstructorInjectionPoint;
	import org.swiftsuspenders.typedescriptions.PostConstructInjectionPoint;
	import org.swiftsuspenders.typedescriptions.PreDestroyInjectionPoint;
	import org.swiftsuspenders.typedescriptions.PropertyInjectionPoint;
	import org.swiftsuspenders.typedescriptions.TypeDescription;

	public class DescribeTypeReflector extends ReflectorBase implements Reflector
	{
		//----------------------       Private / Protected Properties       ----------------------//
		private var _currentFactoryDefinition : TypeDefinition;

		//----------------------               Public Methods               ----------------------//
		public function typeImplements(type : Class, superType : Class) : Boolean
		{
            if (type == superType)
            {
	            return true;
            }

            var type1 : TypeDefinition = describeType(type);
			var type2 : TypeDefinition = describeType(superType);

			return isDerivedType(type1, type2);
		}

		public function describeInjections(type : Class) : TypeDescription
		{
			_currentFactoryDefinition = describeType(type);
			const description : TypeDescription = new TypeDescription(false);
			addCtorInjectionPoint(description, type);
			addFieldInjectionPoints(description);
			addMethodInjectionPoints(description);
			addPostConstructMethodPoints(description);
			addPreDestroyMethodPoints(description);
			_currentFactoryDefinition = null;
			return description;
		}

		//----------------------         Private / Protected Methods        ----------------------//
		/**
		 *
		 * @royaleignorecoercion Object
		 */
		private function addCtorInjectionPoint(description : TypeDescription, type : Class) : void
		{
			/*const node : XML = _currentFactoryDefinition.constructor[0];
			if (!node)
			{
				if (_currentFactoryDefinition.parent().@name == 'Object'
						|| _currentFactoryDefinition.extendsClass.length() > 0)
				{
					description.ctor = new NoParamsConstructorInjectionPoint();
				}
				return;
			}*/

			var constructor:MethodDefinition = _currentFactoryDefinition.constructorMethod;
			const paramDefinitions:Array = constructor.parameters;
			if (paramDefinitions.length == 0) {
				description.ctor = new NoParamsConstructorInjectionPoint();
				return;
			}


			const injectParameters : Object = extractInjectMetaData(_currentFactoryDefinition);
			const parameterNames : Array = (injectParameters.name || '').split(',');

			//const parameterNodes : XMLList = node.parameter;
			/*
			 In many cases, the flash player doesn't give us type information for constructors until
			 the class has been instantiated at least once. Therefore, we do just that if we don't get
			 type information for at least one parameter.
			 */
			/*if (parameterNodes.(@type == '*').length() == parameterNodes.@type.length())
			{
				createDummyInstance(node, type);
			}*/
			const parameters : Array = gatherMethodParameters(paramDefinitions, parameterNames);
			const requiredParameters : uint = (parameters as Object).required;
			delete (parameters as Object).required;
			description.ctor = new ConstructorInjectionPoint(parameters, requiredParameters,
				injectParameters);
		}
		private function extractInjectMetaData(definition : DefinitionWithMetaData) : Object
		{
			var parametersMap : Object = {};
			var metas:Array = definition.metadata;

			var length : uint = metas.length;
			for (var i : int = 0; i < length; i++)
			{
				var meta : MetaDataDefinition = metas[i] as MetaDataDefinition;
				if (meta.name != 'Inject') continue;
				var args: Array = meta.args;
				var arglen:uint = args.length;
				for (var ii:int =0; ii<arglen; ii++) {
					var arg:MetaDataArgDefinition = args[ii] as MetaDataArgDefinition;
					parametersMap[arg.key] = arg;
				}
				/*var key : String = parameter.@key;
				parametersMap[key] = parametersMap[key] != undefined  //<--- need to check this 'undefined'
					? parametersMap[key] + ',' + parameter.attribute('value')
					: parameter.attribute('value').toString();*/
			}
			return parametersMap;
		}

		private function extractTagParameters(tag : String, definition : DefinitionWithMetaData) : Object
		{
			var metadata:Array = definition.metadata;
			var length : uint = metadata.length ;
			for (var i : int = 0; i < length; i++)
			{
				var entry : MetaDataDefinition = metadata[i] as MetaDataDefinition;
				if (entry.name == tag)
				{

					const parametersList : Array = entry.args;
					const parametersMap : Object = {};
					const parametersCount : int = parametersList.length;
					for (var j : int = 0; j < parametersCount; j++)
					{
						const parameter : MetaDataArgDefinition = parametersList[j] as MetaDataArgDefinition;
						parametersMap[parameter.key] = parametersMap[parameter.key] != undefined
								? parametersMap[parameter.key] + ',' + parameter.value
								: parameter.value;
					}
					parametersMap['_'] = parametersList; //@todo consider removing
					return parametersMap;
				}
			}
			return null;
		}


		private function addFieldInjectionPoints(description : TypeDescription) : void
		{

			var injectFields:Array = getMembersWithMetadata(_currentFactoryDefinition ,'Inject', false, MemberTypes.ACCESSORS |  MemberTypes.VARIABLES);

			for each(var fieldDefinition:VariableDefinition in injectFields) {

				var injectMetas:Array = fieldDefinition.retrieveMetaDataByName('Inject');
				var injectMeta:MetaDataDefinition = injectMetas[0];
				var nameArg:MetaDataArgDefinition = injectMeta.getArgsByKey('name')[0];

				var mappingId : String =
						fieldDefinition.type.qualifiedName + '|' + nameArg ? nameArg.value : '';
				var propertyName : String = fieldDefinition.name;

				const injectParameters : Object = extractInjectMetaData(fieldDefinition);

				var injectionPoint : PropertyInjectionPoint = new PropertyInjectionPoint(mappingId,
						propertyName, injectParameters.optional, injectParameters);
				description.addInjectionPoint(injectionPoint);

			}



			/*for each (var node : XML in _currentFactoryDefinition.*.
					(name() == 'variable' || name() == 'accessor').metadata.(@name == 'Inject'))
			{
				var mappingId : String =
						node.parent().@type + '|' + node.arg.(@key == 'name').attribute('value');
				var propertyName : String = node.parent().@name;
				const injectParameters : Object = extractInjectMetaData(node.arg);
				var injectionPoint : PropertyInjectionPoint = new PropertyInjectionPoint(mappingId,
					propertyName, injectParameters.optional == 'true', injectParameters);
				description.addInjectionPoint(injectionPoint);
			}*/
		}

		/*
		private function extractInjectMetaData(definition : DefinitionWithMetaData) : Object
		{
			var parametersMap : Object = {};
			var metas:Array = definition.metadata;

			var length : uint = metas.length;
			for (var i : int = 0; i < length; i++)
			{
				var meta : MetaDataDefinition = metas[i] as MetaDataDefinition;
				if (meta.name != 'Inject') continue;
				var args: Array = meta.args;
				var arglen:uint = args.length;
				for (var ii:int =0; ii<arglen; ii++) {
					var arg:MetaDataArgDefinition = args[ii] as MetaDataArgDefinition;
					parametersMap[arg.key] = arg;
				}
				/*var key : String = parameter.@key;
				parametersMap[key] = parametersMap[key] != undefined  //<--- need to check this 'undefined'
					? parametersMap[key] + ',' + parameter.attribute('value')
					: parameter.attribute('value').toString();
				}
			return parametersMap;
			}
		private function addFieldInjectionPoints(description : TypeDescription) : void
		{
			for each (var node : XML in _currentFactoryDefinition.*.
			(name() == 'variable' || name() == 'accessor').metadata.(@name == 'Inject'))
			{
				var mappingId : String =
						node.parent().@type + '|' + node.arg.(@key == 'name').attribute('value');
				var propertyName : String = node.parent().@name;
				const injectParameters : Dictionary = extractInjectMetaData(node.arg);
				var injectionPoint : PropertyInjectionPoint = new PropertyInjectionPoint(mappingId,
						propertyName, injectParameters.optional == 'true', injectParameters);
				description.addInjectionPoint(injectionPoint);
			}
		}

		 */
		/**
		 *
		 * @royaleignorecoercion Object
		 */
		private function addMethodInjectionPoints(description : TypeDescription) : void
		{
			var injectMethods:Array = getMembersWithMetadata(_currentFactoryDefinition ,'Inject', false, MemberTypes.METHODS);

			for each(var injectMethod:MethodDefinition in injectMethods) {
				const injectParameters : Object = extractInjectMetaData(injectMethod);
				const parameterNames : Array = (injectParameters.name || '').split(',');
				const parameters : Array =
						gatherMethodParameters(injectMethod.parameters, parameterNames);
				const requiredParameters : uint = (parameters as Object).required;
				delete (parameters as Object).required;
				var injectionPoint : MethodInjectionPoint = new MethodInjectionPoint(
						injectMethod.name, parameters, requiredParameters,
						injectParameters.optional, injectParameters);
				description.addInjectionPoint(injectionPoint);

			}


			/*for each (var node : XML in _currentFactoryDefinition.method.metadata.(@name == 'Inject'))
			{
				const injectParameters : Object = extractInjectMetaData(node.arg);
				const parameterNames : Array = (injectParameters.name || '').split(',');
				const parameters : Array =
						gatherMethodParameters(node.parent().parameter, parameterNames);
				const requiredParameters : uint = parameters.required;
				delete parameters.required;
				var injectionPoint : MethodInjectionPoint = new MethodInjectionPoint(
					node.parent().@name, parameters, requiredParameters,
					injectParameters.optional == 'true', injectParameters);
				description.addInjectionPoint(injectionPoint);
			}*/
		}

		private function addPostConstructMethodPoints(description : TypeDescription) : void
		{
			var injectionPoints : Array = gatherOrderedInjectionPointsForTag(
				PostConstructInjectionPoint, 'PostConstruct');
			for (var i : int = 0, length : int = injectionPoints.length; i < length; i++)
			{
				description.addInjectionPoint(injectionPoints[i]);
			}
		}

		private function addPreDestroyMethodPoints(description : TypeDescription) : void
		{
			var injectionPoints : Array = gatherOrderedInjectionPointsForTag(
				PreDestroyInjectionPoint, 'PreDestroy');
			if (!injectionPoints.length)
			{
				return;
			}
			description.preDestroyMethods = injectionPoints[0];
			description.preDestroyMethods.last = injectionPoints[0];
			for (var i : int = 1, length : int = injectionPoints.length; i < length; i++)
			{
				description.preDestroyMethods.last.next = injectionPoints[i];
				description.preDestroyMethods.last = injectionPoints[i];
			}
		}
		/**
		 *
		 * @royaleignorecoercion Object
		 */
		private function gatherMethodParameters(
			parameterDefinitions : Array, parameterNames : Array) : Array
		{
			var requiredParameters : uint = 0;
			const length : uint = parameterDefinitions.length;
			const parameters : Array = new Array(length);
			for (var i : int = 0; i < length; i++)
			{
				var parameter : ParameterDefinition = parameterDefinitions[i];
				var injectionName : String = parameterNames[i] || '';
				var parameterTypeName : String = parameter.type.qualifiedName;
				var optional : Boolean = parameter.optional;
				if (parameterTypeName == '*')
				{
					if (!optional)
					{
						throw new InjectorError('Error in method definition of injectee "' +
							_currentFactoryDefinition.qualifiedName + 'Required parameters can\'t have type "*".');
					}
					else
					{
						parameterTypeName = null;
					}
				}
				if (!optional)
				{
					requiredParameters++;
				}
				parameters[i] = parameterTypeName + '|' + injectionName;
			}
			(parameters as Object).required = requiredParameters;
			return parameters;
		}
		/**
		 *
		 * @royaleignorecoercion Object
		 */
		private function gatherOrderedInjectionPointsForTag(
				injectionPointType : Class, tag : String) : Array
		{
			const injectionPoints : Array = [];
			var tagMembers:Array = getMembersWithMetadata(_currentFactoryDefinition ,tag, false, MemberTypes.METHODS ); //@todo review... this assumes methods only, but original did not
			for each (var methodDefinition:MethodDefinition in tagMembers)
			{

				const injectParameters : Object = extractInjectMetaData(methodDefinition);
				const parameterNames : Array = (injectParameters.name || '').split(',');
				const parameters : Array =
						gatherMethodParameters(methodDefinition.parameters, parameterNames);
				const requiredParameters : uint = (parameters as Object).required;
				delete (parameters as Object).required;
				var tags:Array = methodDefinition.retrieveMetaDataByName(tag);
				for (var metaTag:MetaDataDefinition in tags) {
					var orderTag:MetaDataArgDefinition = metaTag.getArgsByKey('order')[0];
					var order : Number = orderTag? parseInt(orderTag.value) :  NaN;
					injectionPoints.push(new injectionPointType(methodDefinition.name,
							parameters, requiredParameters, isNaN(order) ? int.MAX_VALUE : order));
				}



			}

			/*for each (var node : XML in
				_currentFactoryDefinition..metadata.(@name == tag))
			{
				const injectParameters : Object = extractInjectMetaData(node.arg);
				const parameterNames : Array = (injectParameters.name || '').split(',');
				const parameters : Array =
					gatherMethodParameters(node.parent().parameter, parameterNames);
				const requiredParameters : uint = parameters.required;
				delete parameters.required;
				var order : Number = parseInt(node.arg.(@key == 'order').@value);
				injectionPoints.push(new injectionPointType(node.parent().@name,
					parameters, requiredParameters, isNaN(order) ? int.MAX_VALUE : order));
			}*/
			if (injectionPoints.length > 0)
			{
				injectionPoints.sortOn('order', Array.NUMERIC);
			}
			return injectionPoints;
		}

		/*private function createDummyInstance(constructorNode : XML, clazz : Class) : void
		{
			try
			{
				switch (constructorNode.children().length())
				{
					case 0 :(new clazz());break;
					case 1 :(new clazz(null));break;
					case 2 :(new clazz(null, null));break;
					case 3 :(new clazz(null, null, null));break;
					case 4 :(new clazz(null, null, null, null));break;
					case 5 :(new clazz(null, null, null, null, null));break;
					case 6 :(new clazz(null, null, null, null, null, null));break;
					case 7 :(new clazz(null, null, null, null, null, null, null));break;
					case 8 :(new clazz(null, null, null, null, null, null, null, null));break;
					case 9 :(new clazz(null, null, null, null, null, null, null, null, null));break;
					case 10 :
						(new clazz(null, null, null, null, null, null, null, null, null, null));
						break;
				}
			}
			catch (error : Error)
			{
				trace('Exception caught while trying to create dummy instance for constructor ' +
						'injection. It\'s almost certainly ok to ignore this exception, but you ' +
						'might want to restructure your constructor to prevent errors from ' +
						'happening. See the Swiftsuspenders documentation for more details.\n' +
						'The caught exception was:\n' + error);
			}
			constructorNode.setChildren(describeType(clazz).factory.constructor[0].children());
		}*/
	}
}