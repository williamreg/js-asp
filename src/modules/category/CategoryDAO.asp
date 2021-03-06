<!--#include file="../../dao/DAO.asp" -->
<!--#include file="Category.asp" -->
<script language="javascript" runat="server">
function CategoryDAO() {
	this.table = "Category";
}

CategoryDAO.toPojo = function(record) {
	var category = new Category();
	category.id = record.get("id");
	var parentId = record.get("parentId");
	if (parentId) category.parent = new Category(parentId);
	category.name = record.get("name");
	category.description = record.get("description");
	return category;
}

CategoryDAO.fromPojo = function(category) {
	var record = {};
	if (category.parent) record.parentId = category.parent.id;
	record.name = category.name;
	record.description = category.description;
	return new Map(record);
}

CategoryDAO.prototype = new DAO();

CategoryDAO.prototype.get = function(id, withSubs) {
	if (!withSubs) { // Only one record
		var sql = "SELECT TOP 1 id, lFlag, rFlag, parentId";
		sql += ", name, description";
		sql += " FROM [" + this.table + "] WHERE id = " + id;
		var record = this.db.query(sql, 1);
		if (!record) return;
		return CategoryDAO.toPojo(record);
	}
	// Also get sub categories
	var sql = "SELECT id, parentId, lFlag, rFlag";
	sql += ", name, description";
	sql += " FROM [" + this.table + "]";
	if (id) {
		var record = this.db.query("SELECT TOP 1 lFlag, rFlag FROM [" + this.table + "] WHERE id = " + id, 1);
		sql += " WHERE lFlag BETWEEN " + record.get("lFlag") + " AND " + record.get("rFlag");
	}
	sql += " ORDER BY lFlag";

	var records = this.db.query(sql);
	if (!records) return;

	var root = new Category();
	var lastCategory;
	records.forEach(function(record) {
		var category = CategoryDAO.toPojo(record);

		if (!category.parent) root.push(category);
		else if (category.parent.id == lastCategory.id) lastCategory.push(category);
		else { // Last node's parent node's node
			var parent = lastCategory.parent;
			while (category.parent.id != parent.id) parent = parent.parent;
			parent.push(category);
		}
		lastCategory = category;
	});
	return root;
}

CategoryDAO.prototype.move = function(id, isDown) {
	if (isDown) {
		var before = this.db.query("SELECT lFlag, rFlag FROM [" + this.table + "] WHERE id = " + id, 1);
		var after = this.db.query("SELECT lFlag, rFlag FROM [" + this.table + "] WHERE lFlag = " + (before.get("rFlag") + 1), 1);
		if (!after) return;
	} else {
		var after = this.db.query("SELECT lFlag, rFlag FROM [" + this.table + "] WHERE id = " + id, 1);
		var before = this.db.query("SELECT lFlag, rFlag FROM [" + this.table + "] WHERE rFlag = " + (after.get("lFlag") - 1), 1);
		if (!before) return;
	}
	before.lFlag = before.get("lFlag");
	before.rFlag = before.get("rFlag");
	after.lFlag = after.get("lFlag");
	after.rFlag = after.get("rFlag");

	var subValue = after.lFlag - before.lFlag;
	var plusValue = after.rFlag - before.rFlag;
	this.db.doTrans(function() {
		this.db.update(this.table,
			"lFlag = - (lFlag + " + plusValue + "), rFlag = - (rFlag + " + plusValue + ")",
			"lFlag BETWEEN " + before.lFlag + " AND " + before.rFlag);
		this.db.update(this.table,
			"lFlag = lFlag - " + subValue + ", rFlag = rFlag - " + subValue,
			"lFlag BETWEEN " + after.lFlag + " AND " + after.rFlag);
		this.db.update(this.table,
			"lFlag = - lFlag, rFlag = - rFlag",
			"lFlag BETWEEN - " + (before.lFlag + plusValue) + " AND - " + (before.rFlag + plusValue));
	}, this);
}

CategoryDAO.prototype.up = function(id) {
	return this.move(id);
}

CategoryDAO.prototype.down = function(id) {
	return this.move(id, true);
}

CategoryDAO.prototype.save = function(category) {
	if (!category.parent) { // Save to root
		var maxFlag = this.db.query("SELECT MAX(rFlag) AS maxFlag FROM [" + this.table + "]", 1).get("maxFlag");
		var saveItem = {
			parentId: null,
			depth: 0,
			lFlag: maxFlag + 1,
			rFlag: maxFlag + 2,
			name: category.name
		}
		this.db.insert(this.table, new Map(saveItem));
	} else {
		var pCate = this.db.query("SELECT depth, rFlag FROM [" + this.table + "] WHERE id = " + category.parent.id, 1);
		if (!pCate) throw new Error("Do not have this category. You can't add sub category to this.");
		this.db.doTrans(function() {
			var rFlag = pCate.get("rFlag");
			var depth = pCate.get("depth");
			this.db.update(this.table, "rFlag = rFlag + 2", "rFlag >= " + rFlag);
			this.db.update(this.table, "lFlag = lFlag + 2", "lFlag >= " + rFlag);
			var saveItem = {
				parentId: category.parent.id,
				depth: depth + 1,
				lFlag: rFlag,
				rFlag: rFlag + 1,
				name: category.name
			}
			this.db.insert(this.table, new Map(saveItem));
		}, this);
	}
}

CategoryDAO.prototype.update = function(id, category) {
	if (!id) id = category.id;

	var record = CategoryDAO.fromPojo(category);
	this.db.update(this.table, record, "id = " + id);
}

CategoryDAO.prototype.del = function(id) {
	var sql = "SELECT TOP 1 id, lFlag, rFlag";
	sql += " FROM [" + this.table + "] WHERE id = " + id;
	var record = this.db.query(sql, 1);
	if (!record) return;
	lFlag = record.get("lFlag");
	rFlag = record.get("rFlag");
	if (rFlag - lFlag != 1) return;

	this.db.doTrans(function() {
		this.db.update(this.table, "rFlag = rFlag - 2", "rFlag > " + lFlag);
		this.db.update(this.table, "lFlag = lFlag - 2", "lFlag > " + lFlag);
		this.db.del(this.table, "id = " + id);
	}, this);
}
</script>