/*
 * Copyright (c) 2012 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file 
 * in accordance with the terms of the license agreement accompanying it.
 */
package
{


/**
     *  @private
     *  This class is used to link additional classes into  this swc lib
     *  beyond those that are found by dependency analysis starting
     *  from the classes specified in manifest.xml.
     */
    internal class SwiftSuspendersClasses
    {

        import org.swiftsuspenders.dependencyproviders.ClassProvider; ClassProvider;
        import org.swiftsuspenders.dependencyproviders.DependencyProvider; DependencyProvider;
        import org.swiftsuspenders.dependencyproviders.FactoryProvider; FactoryProvider;
        import org.swiftsuspenders.dependencyproviders.FallbackDependencyProvider; FallbackDependencyProvider;
        import org.swiftsuspenders.dependencyproviders.ForwardingProvider; ForwardingProvider;
        import org.swiftsuspenders.dependencyproviders.InjectorUsingProvider; InjectorUsingProvider;
        import org.swiftsuspenders.dependencyproviders.LocalOnlyProvider; LocalOnlyProvider;
        import org.swiftsuspenders.dependencyproviders.OtherMappingProvider; OtherMappingProvider;
        import org.swiftsuspenders.dependencyproviders.SingletonProvider; SingletonProvider;
        import org.swiftsuspenders.dependencyproviders.SoftDependencyProvider; SoftDependencyProvider;
        import org.swiftsuspenders.dependencyproviders.ValueProvider; ValueProvider;
  
        import org.swiftsuspenders.errors.InjectorError; InjectorError;
        import org.swiftsuspenders.errors.InjectorInterfaceConstructionError; InjectorInterfaceConstructionError;
        import org.swiftsuspenders.errors.InjectorMissingMappingError; InjectorMissingMappingError;

        import org.swiftsuspenders.mapping.InjectionMapping; InjectionMapping;
        import org.swiftsuspenders.mapping.MappingEvent; MappingEvent;
        import org.swiftsuspenders.mapping.ProviderlessMapping; ProviderlessMapping;
        import org.swiftsuspenders.mapping.UnsealedMapping; UnsealedMapping;
    
        import org.swiftsuspenders.reflection.DescribeTypeReflector; DescribeTypeReflector;
        import org.swiftsuspenders.reflection.Reflector; Reflector;
        import org.swiftsuspenders.reflection.ReflectorBase; ReflectorBase;
   
        import org.swiftsuspenders.typedescriptions.ConstructorInjectionPoint; ConstructorInjectionPoint;
        import org.swiftsuspenders.typedescriptions.InjectionPoint; InjectionPoint;
        import org.swiftsuspenders.typedescriptions.MethodInjectionPoint; MethodInjectionPoint;
        import org.swiftsuspenders.typedescriptions.NoParamsConstructorInjectionPoint; NoParamsConstructorInjectionPoint;
        import org.swiftsuspenders.typedescriptions.OrderedInjectionPoint; OrderedInjectionPoint;
        import org.swiftsuspenders.typedescriptions.PostConstructInjectionPoint; PostConstructInjectionPoint;
        import org.swiftsuspenders.typedescriptions.PreDestroyInjectionPoint; PreDestroyInjectionPoint;
        import org.swiftsuspenders.typedescriptions.PropertyInjectionPoint; PropertyInjectionPoint;
        import org.swiftsuspenders.typedescriptions.TypeDescription; TypeDescription;

        import org.swiftsuspenders.utils.SsInternal; SsInternal;
        import org.swiftsuspenders.utils.TypeDescriptor; TypeDescriptor;
        import org.swiftsuspenders.InjectionEvent; InjectionEvent;
        import org.swiftsuspenders.Injector; Injector;

    }
}
