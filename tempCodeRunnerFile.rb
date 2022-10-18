        if content.match /\{\{(.*)\}\}/ #ex grabs {{name}}
          attribute = content.tr("{}", "")  #removes {{}} = > name
          content = attributes[attr.to_sym][attribute.to_sym] #this works
        else