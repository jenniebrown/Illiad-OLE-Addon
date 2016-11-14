local settings = {};
settings.scriptActive = GetSetting("Active");
settings.username = GetSetting("OLEUsername");
settings.password = GetSetting("OLEPassword");
local interfaceManager = nil;
local OLEForm = {};

OLEForm.Form = nil;
OLEForm.Browser = nil;
OLEForm.RibbonPage = nil;

function Init()
	interfaceManager = GetInterfaceManager();
	OLEForm.Form = interfaceManager:CreateForm("OLE", "Script");
	OLEForm.Browser = OLEForm.Form:CreateBrowser("OLE", "OLE", "OLE");
	-- Don't display text label on browser 
	OLEForm.Browser.TextVisible = false;
	
	-- Ribbon page was automatically created when we created the browser. Use the name specified in browser --
	OLEForm.RibbonPage = OLEForm.Form:GetRibbonPage("OLE");	
	-- Creates a button on the ribbon above the browser. 3rd argument is name of function to call when clicked --
	OLEForm.RibbonPage:CreateButton("Barcode Refresh", GetClientImage("Search32"), "StartRequestProcess", "OLE");
	OLEForm.RibbonPage:CreateButton("Transit Slip", GetClientImage("Search32"), "GenerateTransitSlip", "OLE");
	
	OLEForm.Form:Show();
	StartRequestProcess();

end

-- Navigate to Search Request page in OLE
function StartRequestProcess()
	local URL = "https://"..settings.username .. ":" .. settings.password .. "@oletest.lib.lehigh.edu/olefs/portal.do?channelTitle=Request%20Search&channelUrl=https://oletest.lib.lehigh.edu/olefs/ole-kr-krad/lookup?methodToCall=start&dataObjectClassName=org.kuali.ole.deliver.bo.OleDeliverRequestBo&returnLocation=https://oletest.lib.lehigh.edu/olefs/portal.do&hideReturnLink=true&showMaintenanceLinks=true";
	OLEForm.Browser:Navigate(URL);
	OLEForm.Browser:RegisterPageHandler("formExists", "kualiForm", "CreateRequest", false);
end

-- Navigate to create new request form by clicking Create New on the kualiForm
function CreateRequest()
	local createNew = OLEForm.Browser:GetFormElementFromFormName("kualiForm", "uif-Ole-CreateNewLink");
	OLEForm.Browser:ClickObjectByReference(createNew);
	OLEForm.Browser:RegisterPageHandler("formExists", "kualiForm", "SetRequestType", false);
end

-- Set field value for Request Type in dropdown in kualiForm. This causes the page to refresh to load new fields. Also set User Barcode
function SetRequestType()
	OLEForm.Browser:SetFormValue("kualiForm", "selectRequestBorrower-MaintenanceView-requestTypeIds_control", "Page/Hold Request");
	OLEForm.Browser:SetFormValue("kualiForm", "selectRequestBorrower-MaintenanceView-borrowerBarcodes_control", GetFieldValue("Transaction", "SSN"));
	OLEForm.Browser:RegisterPageHandler("formExists", "kualiForm", "SetPickupLocation", false);
end

-- Set pickup location to FAIRCHILD. Other options are "10": PALCI, "11": API, "12": LINDERMAN. Also set Item Barcode
function SetPickupLocation()
	OLEForm.Browser:SetFormValue("kualiForm", "recallRequest-MaintenanceView-pickupLocation_control", "13");
	OLEForm.Browser:SetFormValue("kualiForm", "PageRequest-itemId_control", GetFieldValue("Transaction", "Location"));
	OLEForm.Browser:SetFormValue("kualiForm", "request-note_control", GetFieldValue("Transaction", "TransactionNumber"));
	OLEForm.Browser:RegisterPageHandler("formExists", "kualiForm", "SubmitKualiForm", false);
end

-- Submit request in OLE. Page will reload and tell user if there are any errors.
function SubmitKualiForm()
	local submit = OLEForm.Browser:GetFormElementFromFormName("kualiForm", "u64");
	OLEForm.Browser:ClickObjectByReference(submit);
end

-- Take user to returns page in OLE. Returning an item on hold will generate the transit slip
function GenerateTransitSlip()
	OLEForm.Browser:Navigate("https://oletest.lib.lehigh.edu/olefs/portal.do?channelTitle=Return&channelUrl=https://oletest.lib.lehigh.edu/olefs/ole-kr-krad/checkincontroller?viewId=checkinView&methodToCall=start");
	OLEForm.Browser:RegisterPageHandler("formExists", "kualiForm", "SetReturnField", false);
end

-- Fill barcode field with item barcode. User must submit form themselves
function SetReturnField()
	OLEForm.Browser:SetFormValue("kualiForm", "checkIn-Item_control", GetFieldValue("Transaction", "Location"));
end

