<script language="javascript" runat="server">
function PutAction() {
	this.method = "PUT";
	this.form = {}
	this.hasError = false;
}
PutAction.prototype = new Action();

function DBActionFormItem(value) {
	this.input = null;

	this.valueOf = function() {
		return value;
	}
}

PutAction.prototype.getIdParam = function() {
	if (this.input.id) {
		try {
			return this.getNumber(this.input.id, 1);
		} catch (e) {
			return 0;
		}
	}
	return 0;
}

PutAction.prototype.withStringParam = function(name, value, minLength, maxLength, matchs) {
	var obj, names = name.split(".");
	for (obj = this.form, i = 0; i < names.length; i++) {
		if (!obj[names[i]]) obj[names[i]] = {};
		obj = obj[names[i]];
	}
	this.form = obj;
	var form = this.form[name] = new DBActionFormItem(this.input[name]);
	if (!form.valueOf()) {
		if (value == true) form.error = new Error(0, this.lang(name + "Required"));
		else this.param[name] = value || null;
	} else {
		try {
			this.param[name] = this.getString(form.valueOf(), minLength, maxLength, matchs);
		} catch (e) {
			switch (e.number) {
				case 2: e.description = this.lang(name + "Short"); break;
				case 3: e.description = this.lang(name + "Long"); break;
				case 4: e.description = this.lang(name + "NotMatch"); break;
				default: e.description = this.lang("unknownError");
			}
			form.error = e;
		}
	}
	if (form.error) this.hasError = true;
}

PutAction.prototype.withStringsParam = function(name, value, spliter, minLength, maxLength, matchs) {
	if (!spliter) spliter = /,\s*/ig;
	var form = this.form[name] = new DBActionFormItem(this.input[name]);
	if (!form.valueOf()) {
		if (value == true) form.error = new Error(0, this.lang(name + "Required"));
		else this.param[name] = value || null;
	} else this.param[name] = this.getStrings(form.valueOf(), spliter, minLength, maxLength, matchs);
	if (form.error) this.hasError = true;
}

PutAction.prototype.withNumberParam = function(name, value, min, max, matchs) {
	var form = this.form[name] = new DBActionFormItem(this.input[name]);
	if (!form.valueOf()) {
		if (value == true) form.error = new Error(0, this.lang(name + "Required"));
		else if (value) this.param[name] = value;
		else this.param[name] = null;
	} else {
		try {
			this.param[name] = this.getNumber(form.valueOf(), min, max, matchs);
		} catch (e) {
			switch (e.number) {
				case 1: e.description = this.lang(name + "Wrong"); break;
				case 2: e.description = this.lang(name + "Small"); break;
				case 3: e.description = this.lang(name + "Big"); break;
				case 4: e.description = this.lang(name + "NotMatch"); break;
				default: e.description = this.lang("unknownError");
			}
			form.error = e;
		}
	}
	if (form.error) this.hasError = true;
}

PutAction.prototype.withEmailParam = function(name, value) {
	var form = this.form[name] = new DBActionFormItem(this.input[name]);
	if (!form.valueOf()) {
		if (value == true) form.error = new Error(0, this.lang(name + "Required"));
		else if (value) this.param[name] = value;
		else this.param[name] = null;
	} else {
		try {
			this.param[name] = this.getString(form.valueOf(), null, null, (/^[\w]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$/ig));
		} catch (e) {
			switch (e.number) {
				case 4: e.description = this.lang(name + "Wrong"); break;
				default: e.description = this.lang("unknownError");
			}
			form.error = e;
		}
	}
	if (form.error) this.hasError = true;
}

PutAction.prototype.withDateParam = function(name, value, min, max, matchs) {
	var form = this.form[name] = new DBActionFormItem(this.input[name]);
	if (!form.valueOf()) {
		if (value == true) form.error = new Error(0, this.lang(name + "Required"));
		else if (value) this.param[name] = value;
		else this.param[name] = null;
	} else {
		try {
			this.param[name] = this.getDate(form.valueOf(), min, max, matchs);
		} catch (e) {
			switch (e.number) {
				case 1: e.description = this.lang(name + "Wrong"); break;
				case 2: e.description = this.lang(name + "Small"); break;
				case 3: e.description = this.lang(name + "Big"); break;
				case 4: e.description = this.lang(name + "NotMatch"); break;
				default: e.description = this.lang("unknownError");
			}
			form.error = e;
		}
	}
	if (form.error) this.hasError = true;
}

PutAction.prototype.withBooleanParam = function(name) {
	var form = this.form[name] = new DBActionFormItem(this.input[name]);
	if (!form.valueOf()) this.param[name] = false;
	else this.param[name] = true;
}

PutAction.prototype.setParamError = function(name, error) {
	this.form[name].error = error;
	this.hasError = true;
}

PutAction.prototype.getIdsParam = function() {
	if (this.input.ids) return this.getNumbers(this.ids, (/\,/ig), 0);
}

</script>