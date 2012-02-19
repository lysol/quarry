class Input
    constructor: (@longname, @name, @id=null, _class=null) ->
        if !@id
            @id = @name
        if _class
            @class = """class="#{_class}" """
        else
            @class = ''

    render: (value) -> 
        if !value
            value = ''
        """
        <label for="#{@name}">#{@longname}</label>
        <input #{@class}id="#{@id}" type="text" name="#{@name}" value="#{value}" />
        """

class PasswordInput extends Input
    render: (value) -> 
        if !value
            value = ''
        """
        <label for="#{@name}">#{@longname}</label>
        <input #{@class}type="password" id="#{@id}" type="text" name="#{@name}" value="#{value}" />
        """

class Select
    constructor: (@longname, @name, @options, @id=null, _class=null) ->
        if !@id
            @id = @name
        if _class
            @class = """class="#{_class}" """
        else
            @class = ''

    render: (value) ->
        payload = ""
        payload += "<label for=\"#{@name}\">#{@longname}</label>"
        payload += """<select id="#{@id}" #{@class}name="#{@name}">"""
        for option in @options
            if option.value == value
                c = 'selected'
            else
                c = ''
            if option.text
                payload += """<option value="#{option.value}" #{c} >#{option.text}</option>"""
            else
                payload += """<option value="#{option.value}" #{c} >#{option.value}</option>"""
        payload += "</select>"
        return payload

class Checkbox
    constructor: (@longname, @name, @checked, @id=null, _class=null) ->
        if !id
            @id = @name
        if _class
            @class = """class="#{_class}" """
        else
            @class = ''

    render: (value) ->
        if !value
            value = ''
        if @checked
            c = 'checked'
        else
            c = ''
        return """
            <label for="#{@name}">#{@longname}</label>
            <input type="checkbox" name="#{@name}" value="#{value}" #{c} />
            """

class Button
    constructor: (@text, @id=null, _class='btn', @_type='submit') ->
        if @id
            @id = """ id="#{id}" """
        else
            @id = ''
        if _class
            @class = """ class="#{_class}" """
        else
            @class = ''

    render: -> """<button type="#{@_type}" #{@id}#{@class}>#{@text}</button>"""


class Form
    constructor: (@elements, @id=null, _class=null) ->
        if @id
            @id = """ id="#{id}" """
        else
            @id = ''
        if _class
            @class = """ class="#{_class}" """
        else
            @class = ''

    render: (values={}, action='', method="POST") ->
        payload = """<form#{@id}#{@class} method="#{method}" action="#{action}">"""
        for element in @elements
            if element.name in values and values[element.name] != undefined
                payload += element.render values[element.name]
            else
                payload += element.render()
        payload += "</form>"
        return payload


class LoginForm extends Form
    constructor: (id, _class) ->
        elements = [
            new Input('Username or Email', 'login'),
            new PasswordInput('Password', 'password'),
            new Button('Login')
        ]
        super elements, id, _class


class RegisterForm extends Form
    constructor: (id, _class) ->
        elements = [
            new Input('Username', 'username'),
            new Input('Email', 'email'),
            new PasswordInput('Password', 'password'),
            new PasswordInput('Password (again)', 'password2'),
            new Button('Register')
        ]
        super elements, id, _class


exports.LoginForm = LoginForm
exports.RegisterForm = RegisterForm
