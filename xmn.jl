module xmn
    export imports
    
    function imports(module_ref)
        require(join([module_ref], ""))
        return module_ref
    end
end
