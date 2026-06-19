


tryGetServerInfo();

document.getElementById('ManageApps').addEventListener('click', function() {
	document.location = '/manager';
});

document.getElementById('ManagePAS').addEventListener('click', function() {
	document.location = '/oemanager/';
});

function tryGetUrl(url) {

	var xhr = new XMLHttpRequest();
	xhr.onload = function () {
		if (xhr.status !== 200) {
			// Let the caller handle a null object return value
			// throw new Error();
			updateServerInfo(null);
		} else {
			var jsonObject = JSON.parse(xhr.responseText);
			updateServerInfo(jsonObject);
		}

	}
	xhr.open('GET', url, true);
	xhr.send(null);
}

function tryGetServerInfo() {

	try {
		tryGetUrl('../server');
	} catch (e) {

	}
}

function updateServerInfo(jsonObject) {

	var apsv = document.getElementById('apsv');
	var soap = document.getElementById('soap');
	var rest = document.getElementById('rest');
	var manager = document.getElementById('manager');

	if (jsonObject) {
		document.getElementById('OEVersion').textContent = sanitizeInput(jsonObject.ServerInfo.OEVersion);
		document.getElementById('TCVersion').textContent = sanitizeInput(jsonObject.ServerInfo.TomcatVersion);
		document.getElementById('JVMVendor').textContent = sanitizeInput(jsonObject.ServerInfo.JVMVendor);
		document.getElementById('JVMVersion').textContent = sanitizeInput(jsonObject.ServerInfo.JVMVersion);
		document.getElementById('PASVersion').textContent = sanitizeInput(jsonObject.ServerInfo.PASVersion);
		document.getElementById('OSName').textContent = sanitizeInput(jsonObject.ServerInfo.OSName);
		document.getElementById('OSVersion').textContent = sanitizeInput(jsonObject.ServerInfo.OSVersion);
		document.getElementById('OSArch').textContent = sanitizeInput(jsonObject.ServerInfo.OSArch);
		document.getElementById('HostName').textContent = sanitizeInput(jsonObject.ServerInfo.HostName);
		document.getElementById('IPAddress').textContent = sanitizeInput(jsonObject.ServerInfo.IPAddress);
		document.getElementById('upTime').textContent = "Server has been running for " + sanitizeInput(jsonObject.UpTime);
	} else {
		// The serverAlert element does not exist
		// document.getElementById('serverAlert').innerHTML = 'Server status
		// information is disabled';
		document.getElementById('OEVersion').textContent = "OpenEdge";
		document.getElementById('TCVersion').textContent = "Unavailable";
		document.getElementById('JVMVendor').textContent = "Unavailable";
		document.getElementById('JVMVersion').textContent = "Unavailable";
		document.getElementById('PASVersion').textContent = "Unavailable";
		document.getElementById('OSName').textContent = "Unavailable";
		document.getElementById('OSVersion').textContent = "Unavailable";
		document.getElementById('OSArch').textContent = "Unavailable";
		document.getElementById('HostName').textContent = "Unavailable";
		document.getElementById('IPAddress').textContent = "Unavailable";
		document.getElementById('upTime').textContent = "Server has been running for: Unavailable";
	}
}

function sanitizeInput(str) { return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;'); }