/*
 * Copyright (c) 2012 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.swiftsuspenders.utils
{

	COMPILE::SWF{
		import flash.utils.Dictionary;
	}

	import org.swiftsuspenders.reflection.Reflector;
	import org.swiftsuspenders.typedescriptions.TypeDescription;

	public class TypeDescriptor
	{
		//----------------------       Private / Protected Properties       ----------------------//
		COMPILE::SWF
		public var _descriptionsCache : Dictionary;
		COMPILE::JS
		public var _descriptionsCache : WeakMap;
		private var _reflector : Reflector;


		//----------------------               Public Methods               ----------------------//
		COMPILE::SWF
		public function TypeDescriptor(reflector : Reflector, descriptionsCache : Dictionary)
		{
			_descriptionsCache = descriptionsCache;
			_reflector = reflector;
		}

		COMPILE::JS
		public function TypeDescriptor(reflector : Reflector, descriptionsCache : WeakMap)
		{
			_descriptionsCache = descriptionsCache;
			_reflector = reflector;
		}
		COMPILE::SWF
		public function getDescription(type : Class) : TypeDescription
		{
			//get type description or cache it if the given type wasn't encountered before
			return _descriptionsCache[type] ||= _reflector.describeInjections(type);
		}

		COMPILE::JS
		public function getDescription(type : Class) : TypeDescription
		{
			var desc:TypeDescription;
			//get type description or cache it if the given type wasn't encountered before
			if (_descriptionsCache.has(type)) {
				desc = _descriptionsCache.get(type);
			} else {
				desc = _reflector.describeInjections(type);
				_descriptionsCache.set(type, desc);
			}
			return desc;
		}
		COMPILE::SWF
		public function addDescription(type : Class, description : TypeDescription) : void
		{
			_descriptionsCache[type] = description;
		}

		COMPILE::JS
		public function addDescription(type : Class, description : TypeDescription) : void
		{
			_descriptionsCache.set(type, description);
		}
	}
}