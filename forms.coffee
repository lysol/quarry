
class Input
    constructor: (@longname, @name, @value, id=null) ->
        if !id
            @id = @name
    render: ->
        return """
            <label for="#{@name}">#{@longname}</label>
            <input id="#{@id}" type="text" name="#{@name}" value="#{@value}" />
            """

class Select
    constructor: (@longname, @name, @value, @options, id=null) ->
        if !id
            @id = @name

    render: ->
        payload = ''
        payload += """<label for="#{@name">#{@longname}</label"""
        payload += """<select name="#{@name}">"""
        for option in @options
            if option.text
                payload += """<option value="#{option.value}">#{option.text}</option>"""
            else
                payload += """<option value="#{option.value}">#{option.value}</option>"""
        payload += "</select>"
        return payload

class Checkbox
    constructor: (@longname, @name, @value, @checked) ->

    render: ->
        if @checked
            c = 'checked'
        else
            c = ''
        return """
            <label for="#{@name}">#{@longname}</label>
            <input type="checkbox" name="#{@name}" value="#{@value}" #{c} />
            """


