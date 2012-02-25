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
        <div class="control-group">
            <label class="control-label" for="quarryForm[#{@name}]">#{@longname}</label>
            <div class="controls">
                <input #{@class}id="#{@id}" type="text" name="quarryForm[#{@name}]" value="#{value}" />
            </div>
        </div>
        """

class PasswordInput extends Input
    render: (value) -> 
        if !value
            value = ''
        """
        <div class="control-group">
            <label class="control-label" for="quarryForm[#{@name}]">#{@longname}</label>
            <div class="controls">
                <input #{@class}type="password" id="#{@id}" type="text" name="quarryForm[#{@name}]" value="#{value}" />
            </div>
        </div>
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
        payload = """<div class="control-group">"""
        payload += "<label class=\"control-label\" for=\"quarryForm[#{@name}]\">#{@longname}</label>"
        payload += """<div class="controls"><select id="#{@id}" #{@class}name="quarryForm[#{@name}]">"""
        for option in @options
            if option.value == value
                c = 'selected'
            else
                c = ''
            if option.text
                payload += """<option value="#{option.value}" #{c} >#{option.text}</option>"""
            else
                payload += """<option value="#{option.value}" #{c} >#{option.value}</option>"""
        payload += "</select></div></div>"
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
            <div class="control-group">
                <label class="control-label" for="quarryForm[#{@name}]">#{@longname}</label>
                <div class="controls">
                    <input type="checkbox" name="quarryForm[#{@name}]" value="#{value}" #{c} />
                </div>
            </div>
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
    constructor: (@elements, @id=null, _class=null, @legend=null) ->
        if @id
            @id = """ id="#{id}" """
        else
            @id = ''
        if _class
            @class = """ class="#{_class}" """
        else
            @class = ''

    render: (values={}, action='', method="POST") ->
        if values.length == 0
            values = req.body.quarryForm
        payload = """<form#{@id}#{@class} method="#{method}" action="#{action}"><fieldset>"""
        if @legend
            payload += "<legend>#{@legend}</legend>"
        for element in @elements
            if element.name in values and values[element.name] != undefined
                payload += element.render values[element.name]
            else
                payload += element.render()
        payload += "</form>"
        return payload


class Div
    constructor: (@class, @id, @elements) ->
    render: -> 
        result = """<div class="#{@class}" id="#{@id}">"""
        result += (el.render() for el in @elements).join "\n"
        result += "</div>"
        return result

class LoginForm extends Form
    constructor: (id, _class) ->
        elements = [
            new Input('Username or Email', 'login'),
            new PasswordInput('Password', 'password'),
            new Div('form-actions', 'login-actions', [new Button('Login')])
        ]
        super elements, id, _class, 'Login'


class RegisterForm extends Form
    constructor: (id, _class) ->
        elements = [
            new Input('Username', 'username'),
            new Input('Email', 'email'),
            new PasswordInput('Password', 'password'),
            new PasswordInput('Password (again)', 'password2'),
            new Div('form-actions', 'register-actions', [new Button('Register')])
        ]
        super elements, id, _class, 'Register'


exports.LoginForm = LoginForm
exports.RegisterForm = RegisterForm
