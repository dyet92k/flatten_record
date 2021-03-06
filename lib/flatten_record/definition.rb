module FlattenRecord
  class Definition
    def initialize(definition, key=nil)
      @definition = definition
      @errors = []
      @methods = {}
      @compute = {}
      @include = {}
      @except = []
      @only = []
      @class_name = nil
      @prefix = nil
      @_key = key
    end
       
    def [](key)
      instance_variable_get "@#{key}"
    end

    def validates_with(target_model, model)
      @target_model = target_model
      @model = model

      @definition.each do |key, value|
        validates(key, value)
      end
    end

    def validates(key, value)
      if protected_methods.include?("validate_#{key}".to_sym)
        send("validate_#{key}", value)    
      else
        @errors << "unknown options '#{key}'"
      end
      self
    end

    def error_message
      @errors.join("\n")
    end

    def valid?
      @errors.blank?
    end

    protected   
    def validate_except(attrs)
      validate_attrs(:except, attrs)
    end
    
    def validate_only(attrs)
      validate_attrs(:only, attrs)
    end
  
    def validate_methods(methods)
      methods.each do |method, type| 
        error = "undefined method '#{method}' in #{@target_model.name}"
        @errors << error unless target_method?(method)        
        @methods[method] = type
      end      
    end

    def validate_include(childs)
      childs.each do |child, child_definition|
        error = "unknown association '#{child}' in '#{@target_model.name.to_s}'"
        assoc = @target_model.reflect_on_association(child)
        @errors << error if assoc.blank?
        @include[child] = Definition.new(child_definition, child)
      end
    end

    def validate_compute(model_methods)
      @compute = model_methods
    end

    def validate_class_name(name)
      error = "undefined class with '#{name}'"
      @errors << error if !Object.const_defined?(name.to_sym)
      @class_name = name
    end

    def validate_prefix(name)
      @prefix = name
    end

    private
    def validate_attrs(name, attrs)
      attrs.each do |attr|
        error = "unknown attribute '#{attr}' in #{@target_model.name.to_s}"
        @errors << error unless target_method?(attr)
        case name
        when :only
          @only << attr
        when :except
          @except << attr
        end
      end
    end
 
    def model_method?(method)
      @model.attribute_method?(method) || 
        @model.method_defined?(method) 
    end
   
    def target_method?(method)
      @target_model.attribute_method?(method) || 
        @target_model.method_defined?(method) 
    end
  end
end
