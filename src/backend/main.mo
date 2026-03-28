import Time "mo:core/Time";
import Array "mo:base/Array";
import AccessControl "authorization/access-control";
import MixinAuthorization "authorization/MixinAuthorization";
import Principal "mo:core/Principal";

actor {

  type Role = { #admin; #staff; #supplier };

  type User = {
    id          : Text;
    username    : Text;
    password    : Text;
    role        : Role;
    businessIds : [Text];
    createdAt   : Int;
  };

  type Business = { id : Text; name : Text };
  type Godown   = { id : Text; name : Text; businessId : Text };

  type SubCategory = {
    id        : Text;
    name      : Text;
    fieldType : Text;
    options   : [Text];
  };

  type Category = {
    id            : Text;
    name          : Text;
    subCategories : [SubCategory];
  };

  type BiltyPrefix     = { id : Text; prefix : Text };
  type TransportTracker = { id : Text; transport : Text; trackingUrl : Text };
  type LoginResult      = { #ok : User; #err : Text };

  type TransitEntry = {
    id          : Text;
    biltyNumber : Text;
    transport   : Text;
    supplier    : Text;
    category    : Text;
    itemName    : Text;
    packages    : Int;
    biltyDate   : Text;
    businessId  : Text;
    enteredBy   : Text;
    createdAt   : Int;
  };

  type QueueBale  = { baleLabel : Text; category : Text; itemName : Text; status : Text };

  type QueueEntry = {
    id          : Text;
    biltyNumber : Text;
    transport   : Text;
    supplier    : Text;
    bales       : [QueueBale];
    businessId  : Text;
    enteredBy   : Text;
    createdAt   : Int;
    delivered   : Bool;
  };

  type GodownQty = { godownId : Text; qty : Int };

  type InwardItem = {
    category     : Text;
    itemName     : Text;
    subCategory  : Text;
    totalQty     : Int;
    shopQty      : Int;
    godownQtys   : [GodownQty];
    purchaseRate : Float;
    saleRate     : Float;
  };

  type InwardSavedEntry = {
    id          : Text;
    biltyNumber : Text;
    transport   : Text;
    supplier    : Text;
    savedBy     : Text;
    savedAt     : Int;
    businessId  : Text;
    items       : [InwardItem];
  };

  type InventoryItem = {
    id           : Text;
    businessId   : Text;
    category     : Text;
    itemName     : Text;
    subCategory  : Text;
    godownQtys   : [GodownQty];
    shopQty      : Int;
    purchaseRate : Float;
    saleRate     : Float;
  };

  type TransferEntry = {
    id            : Text;
    businessId    : Text;
    category      : Text;
    itemName      : Text;
    subCategory   : Text;
    fromType      : Text;
    fromId        : Text;
    toType        : Text;
    toId          : Text;
    qty           : Int;
    rate          : Float;
    transferredBy : Text;
    createdAt     : Int;
  };

  type DeliveryLineItem = {
    category    : Text;
    itemName    : Text;
    subCategory : Text;
    qty         : Int;
    godownId    : Text;
  };

  type DeliveryEntry = {
    id            : Text;
    businessId    : Text;
    deliveryType  : Text;
    biltyNumber   : Text;
    customerName  : Text;
    customerPhone : Text;
    items         : [DeliveryLineItem];
    deliveredBy   : Text;
    createdAt     : Int;
  };

  type SaleLineItem = {
    category    : Text;
    itemName    : Text;
    subCategory : Text;
    qty         : Int;
    rate        : Float;
  };

  type SaleEntry = {
    id         : Text;
    businessId : Text;
    items      : [SaleLineItem];
    recordedBy : Text;
    createdAt  : Int;
  };

  type TxType = { #inward; #transfer; #delivery; #sale; #directStock };

  type TxRecord = {
    id           : Text;
    businessId   : Text;
    txType       : TxType;
    biltyNumber  : Text;
    category     : Text;
    itemName     : Text;
    subCategory  : Text;
    fromLocation : Text;
    toLocation   : Text;
    transport    : Text;
    qty          : Int;
    rate         : Float;
    enteredBy    : Text;
    notes        : Text;
    createdAt    : Int;
  };

  stable var users             : [User]             = [];
  stable var businesses        : [Business]         = [];
  stable var godowns           : [Godown]           = [];
  stable var categories        : [Category]         = [];
  stable var categoryBusinessIds : [(Text, Text)]    = [];
  stable var biltyPrefixes     : [BiltyPrefix]      = [];
  stable var transportTrackers : [TransportTracker] = [];
  stable var transitEntries    : [TransitEntry]     = [];
  stable var queueEntries      : [QueueEntry]       = [];
  stable var inwardSaved       : [InwardSavedEntry] = [];
  stable var inventory         : [InventoryItem]    = [];
  stable var transfers         : [TransferEntry]    = [];
  stable var deliveries        : [DeliveryEntry]    = [];
  stable var sales             : [SaleEntry]        = [];
  stable var txHistory         : [TxRecord]         = [];
  stable var appSettings       : Text               = "{}";

  let accessControlState = AccessControl.initState();
  include MixinAuthorization(accessControlState);

  stable var seeded : Bool = false;
  stable var seedVersion : Nat = 0;

  func seed() {
    // Version 4 forces re-seed with staff/supplier (no suffix)
    if (seedVersion >= 4) {
      // Version 5: fix categories to match real business (Safi/Lungi/Napkin)
      if (seedVersion < 5) {
        seedVersion := 5;
        categories := [
          { id = "cat1"; name = "Safi";
            subCategories = [
              { id = "sc1"; name = "Size";  fieldType = "text";   options = [] },
              { id = "sc2"; name = "Color"; fieldType = "select"; options = ["black","tiranga","mix"] }
            ]
          },
          { id = "cat2"; name = "Lungi";
            subCategories = [
              { id = "sc3"; name = "Size";  fieldType = "select"; options = ["2 mtr","2.25 mtr","2.5 mtr"] },
              { id = "sc4"; name = "Color"; fieldType = "select"; options = ["plain white","plain colour","mix"] }
            ]
          },
          { id = "cat3"; name = "Napkin";
            subCategories = [
              { id = "sc5"; name = "Size"; fieldType = "select"; options = ["14x21","12x18","16x24"] }
            ]
          }
        ];
      };
      return;
    };
    seedVersion := 4;
    businesses := [{ id = "b1"; name = "Demo Business" }];
    godowns    := [
      { id = "g1"; name = "Main Godown";   businessId = "b1" },
      { id = "g2"; name = "Second Godown"; businessId = "b1" }
    ];
    categories := [
      { id = "cat1"; name = "Safi";
        subCategories = [
          { id = "sc1"; name = "Size";  fieldType = "text";   options = [] },
          { id = "sc2"; name = "Color"; fieldType = "select"; options = ["black","tiranga","mix"] }
        ]
      },
      { id = "cat2"; name = "Lungi";
        subCategories = [
          { id = "sc3"; name = "Size";  fieldType = "select"; options = ["2 mtr","2.25 mtr","2.5 mtr"] },
          { id = "sc4"; name = "Color"; fieldType = "select"; options = ["plain white","plain colour","mix"] }
        ]
      },
      { id = "cat3"; name = "Napkin";
        subCategories = [
          { id = "sc5"; name = "Size"; fieldType = "select"; options = ["14x21","12x18","16x24"] }
        ]
      }
    ];
    biltyPrefixes := [
      { id = "p1"; prefix = "sola" },
      { id = "p2"; prefix = "erob" },
      { id = "p3"; prefix = "cheb" },
      { id = "p4"; prefix = "0"    }
    ];
    users := [
      { id = "u1"; username = "admin";     password = "password"; role = #admin;    businessIds = ["b1"]; createdAt = 0 },
      { id = "u2"; username = "staff";     password = "password"; role = #staff;    businessIds = ["b1"]; createdAt = 0 },
      { id = "u3"; username = "supplier";  password = "password"; role = #supplier; businessIds = ["b1"]; createdAt = 0 }
    ];
    transportTrackers := [];
  };

  public func login(username : Text, password : Text) : async LoginResult {
    seed();
    let match = Array.find(users, func(u : User) : Bool {
      u.username == username and u.password == password
    });
    switch (match) {
      case (?u) #ok(u);
      case null  #err("Invalid username or password");
    };
  };

  public query func getUsers() : async [User] { users };

  public func addUser(id : Text, username : Text, password : Text, role : Role, businessIds : [Text]) : async () {
    seed();
    users := Array.append(users, [{ id; username; password; role; businessIds; createdAt = Time.now() }]);
  };

  public func updateUser(id : Text, username : Text, password : Text, role : Role, businessIds : [Text]) : async () {
    users := Array.map(users, func(u : User) : User {
      if (u.id == id) { { id; username; password; role; businessIds; createdAt = u.createdAt } } else u
    });
  };

  public func deleteUser(id : Text) : async () {
    users := Array.filter(users, func(u : User) : Bool { u.id != id });
  };

  public query func getBusinesses() : async [Business] { businesses };

  public func addBusiness(id : Text, name : Text) : async () {
    seed(); businesses := Array.append(businesses, [{ id; name }]);
  };

  public func updateBusiness(id : Text, name : Text) : async () {
    businesses := Array.map(businesses, func(b : Business) : Business {
      if (b.id == id) { { id; name } } else b
    });
  };

  public func deleteBusiness(id : Text) : async () {
    businesses := Array.filter(businesses, func(b : Business) : Bool { b.id != id });
  };

  public query func getGodowns() : async [Godown] { godowns };

  public func addGodown(id : Text, name : Text, businessId : Text) : async () {
    seed(); godowns := Array.append(godowns, [{ id; name; businessId }]);
  };

  public func updateGodown(id : Text, name : Text, businessId : Text) : async () {
    godowns := Array.map(godowns, func(g : Godown) : Godown {
      if (g.id == id) { { id; name; businessId } } else g
    });
  };

  public func deleteGodown(id : Text) : async () {
    godowns := Array.filter(godowns, func(g : Godown) : Bool { g.id != id });
  };

  // Returns all categories (for backup/restore)
  public query func getCategories() : async [Category] { categories };

  // Returns categories filtered by businessId (default "b1" for unmapped)
  public query func getCategoriesByBusiness(businessId : Text) : async [Category] {
    if (businessId == "") return categories;
    Array.filter(categories, func(c : Category) : Bool {
      let bId = switch (Array.find(categoryBusinessIds, func(p : (Text, Text)) : Bool { p.0 == c.id })) {
        case (?p) p.1;
        case null "b1";
      };
      bId == businessId
    })
  };

  public func addCategory(id : Text, name : Text, businessId : Text) : async () {
    seed();
    // Update or insert business mapping
    categoryBusinessIds := Array.filter(categoryBusinessIds, func(p : (Text, Text)) : Bool { p.0 != id });
    categoryBusinessIds := Array.append(categoryBusinessIds, [(id, businessId)]);
    // Add category if not exists
    let exists = Array.find(categories, func(c : Category) : Bool { c.id == id });
    switch (exists) {
      case null categories := Array.append(categories, [{ id; name; subCategories = [] }]);
      case (?_) ();
    };
  };

  public func updateCategory(id : Text, name : Text) : async () {
    categories := Array.map(categories, func(c : Category) : Category {
      if (c.id == id) { { id; name; subCategories = c.subCategories } } else c
    });
  };

  public func deleteCategory(id : Text) : async () {
    categories := Array.filter(categories, func(c : Category) : Bool { c.id != id });
    categoryBusinessIds := Array.filter(categoryBusinessIds, func(p : (Text, Text)) : Bool { p.0 != id });
  };

  public func addSubCategory(categoryId : Text, sc : SubCategory) : async () {
    categories := Array.map(categories, func(c : Category) : Category {
      if (c.id == categoryId) {
        { id = c.id; name = c.name; subCategories = Array.append(c.subCategories, [sc]) }
      } else c
    });
  };

  public func updateSubCategory(categoryId : Text, sc : SubCategory) : async () {
    categories := Array.map(categories, func(c : Category) : Category {
      if (c.id == categoryId) {
        { id = c.id; name = c.name;
          subCategories = Array.map(c.subCategories, func(s : SubCategory) : SubCategory {
            if (s.id == sc.id) sc else s
          })
        }
      } else c
    });
  };

  public func deleteSubCategory(categoryId : Text, subCategoryId : Text) : async () {
    categories := Array.map(categories, func(c : Category) : Category {
      if (c.id == categoryId) {
        { id = c.id; name = c.name;
          subCategories = Array.filter(c.subCategories, func(s : SubCategory) : Bool { s.id != subCategoryId })
        }
      } else c
    });
  };

  public query func getBiltyPrefixes() : async [BiltyPrefix] { biltyPrefixes };

  public func addBiltyPrefix(id : Text, prefix : Text) : async () {
    seed(); biltyPrefixes := Array.append(biltyPrefixes, [{ id; prefix }]);
  };

  public func deleteBiltyPrefix(id : Text) : async () {
    biltyPrefixes := Array.filter(biltyPrefixes, func(p : BiltyPrefix) : Bool { p.id != id });
  };

  public query func getTransportTrackers() : async [TransportTracker] { transportTrackers };

  public func addTransportTracker(id : Text, transport : Text, trackingUrl : Text) : async () {
    seed(); transportTrackers := Array.append(transportTrackers, [{ id; transport; trackingUrl }]);
  };

  public func updateTransportTracker(id : Text, transport : Text, trackingUrl : Text) : async () {
    transportTrackers := Array.map(transportTrackers, func(t : TransportTracker) : TransportTracker {
      if (t.id == id) { { id; transport; trackingUrl } } else t
    });
  };

  public func deleteTransportTracker(id : Text) : async () {
    transportTrackers := Array.filter(transportTrackers, func(t : TransportTracker) : Bool { t.id != id });
  };

  public query func getTransitEntries(businessId : Text) : async [TransitEntry] {
    Array.filter(transitEntries, func(e : TransitEntry) : Bool { e.businessId == businessId })
  };

  public func addTransitEntry(entry : TransitEntry) : async () {
    seed(); transitEntries := Array.append(transitEntries, [entry]);
  };

  public func updateTransitEntry(entry : TransitEntry) : async () {
    transitEntries := Array.map(transitEntries, func(e : TransitEntry) : TransitEntry {
      if (e.id == entry.id) entry else e
    });
  };

  public func deleteTransitEntry(id : Text) : async () {
    transitEntries := Array.filter(transitEntries, func(e : TransitEntry) : Bool { e.id != id });
  };

  public func biltyExists(biltyNumber : Text) : async Bool {
    let inTransit = Array.find(transitEntries, func(e : TransitEntry) : Bool { e.biltyNumber == biltyNumber });
    let inQueue   = Array.find(queueEntries,   func(e : QueueEntry)   : Bool { e.biltyNumber == biltyNumber });
    let inSaved   = Array.find(inwardSaved,    func(e : InwardSavedEntry) : Bool { e.biltyNumber == biltyNumber });
    switch (inTransit) { case (?_) return true; case null {} };
    switch (inQueue)   { case (?_) return true; case null {} };
    switch (inSaved)   { case (?_) return true; case null {} };
    false
  };

  public query func getQueueEntries(businessId : Text) : async [QueueEntry] {
    Array.filter(queueEntries, func(e : QueueEntry) : Bool { e.businessId == businessId and not e.delivered })
  };

  public func addQueueEntry(entry : QueueEntry) : async () {
    seed();
    queueEntries   := Array.append(queueEntries, [entry]);
    transitEntries := Array.filter(transitEntries, func(e : TransitEntry) : Bool { e.biltyNumber != entry.biltyNumber });
  };

  public func updateQueueEntry(entry : QueueEntry) : async () {
    queueEntries := Array.map(queueEntries, func(e : QueueEntry) : QueueEntry {
      if (e.id == entry.id) entry else e
    });
  };

  public func markQueueDelivered(id : Text) : async () {
    queueEntries := Array.map(queueEntries, func(e : QueueEntry) : QueueEntry {
      if (e.id == id) {
        { id = e.id; biltyNumber = e.biltyNumber; transport = e.transport;
          supplier = e.supplier; bales = e.bales; businessId = e.businessId;
          enteredBy = e.enteredBy; createdAt = e.createdAt; delivered = true }
      } else e
    });
  };

  public func deleteQueueEntry(id : Text) : async () {
    queueEntries := Array.filter(queueEntries, func(e : QueueEntry) : Bool { e.id != id });
  };

  public query func getInwardSaved(businessId : Text) : async [InwardSavedEntry] {
    Array.filter(inwardSaved, func(e : InwardSavedEntry) : Bool { e.businessId == businessId })
  };

  public func saveInward(entry : InwardSavedEntry) : async () {
    seed();
    // Only append if not already saved (idempotent)
    let exists = Array.find(inwardSaved, func(e : InwardSavedEntry) : Bool { e.id == entry.id });
    switch (exists) {
      case (?_) { /* already saved, skip */ };
      case null {
        inwardSaved    := Array.append(inwardSaved, [entry]);
      };
    };
    transitEntries := Array.filter(transitEntries, func(e : TransitEntry) : Bool { e.biltyNumber != entry.biltyNumber });
    queueEntries   := Array.filter(queueEntries,   func(e : QueueEntry)   : Bool { e.biltyNumber != entry.biltyNumber });
    // Note: TxRecords are managed by the frontend via addTxRecord to avoid duplicates.
  };

  public func updateInwardSaved(entry : InwardSavedEntry) : async () {
    inwardSaved := Array.map(inwardSaved, func(e : InwardSavedEntry) : InwardSavedEntry {
      if (e.id == entry.id) entry else e
    });
  };

  public func deleteInwardSaved(id : Text) : async () {
    inwardSaved := Array.filter(inwardSaved, func(e : InwardSavedEntry) : Bool { e.id != id });
  };

  public query func getInventory(businessId : Text) : async [InventoryItem] {
    Array.filter(inventory, func(i : InventoryItem) : Bool { i.businessId == businessId or (businessId == "b1" and i.businessId == "") })
  };

  public func addInventoryItem(item : InventoryItem) : async () {
    seed();
    // Upsert: if item with same id exists, update it; otherwise append
    let exists = Array.find(inventory, func(i : InventoryItem) : Bool { i.id == item.id });
    switch (exists) {
      case (?_) {
        inventory := Array.map(inventory, func(i : InventoryItem) : InventoryItem {
          if (i.id == item.id) item else i
        });
      };
      case null {
        inventory := Array.append(inventory, [item]);
      };
    };
  };

  public func updateInventoryItem(item : InventoryItem) : async () {
    inventory := Array.map(inventory, func(i : InventoryItem) : InventoryItem {
      if (i.id == item.id) item else i
    });
  };

  public func deleteInventoryItem(id : Text) : async () {
    inventory := Array.filter(inventory, func(i : InventoryItem) : Bool { i.id != id });
  };

  func applyInventoryAddition(businessId : Text, item : InwardItem) {
    let key = businessId # "|" # item.category # "|" # item.itemName # "|" # item.subCategory;
    let existing = Array.find(inventory, func(i : InventoryItem) : Bool {
      i.businessId == businessId and i.category == item.category
        and i.itemName == item.itemName and i.subCategory == item.subCategory
    });
    switch (existing) {
      case null {
        inventory := Array.append(inventory, [{
          id = key; businessId; category = item.category; itemName = item.itemName;
          subCategory = item.subCategory; godownQtys = item.godownQtys;
          shopQty = item.shopQty; purchaseRate = item.purchaseRate; saleRate = item.saleRate;
        }]);
      };
      case (?inv) {
        var merged = inv.godownQtys;
        for (gq in item.godownQtys.vals()) {
          let found = Array.find(merged, func(g : GodownQty) : Bool { g.godownId == gq.godownId });
          switch (found) {
            case null { merged := Array.append(merged, [gq]) };
            case (?_) {
              merged := Array.map(merged, func(g : GodownQty) : GodownQty {
                if (g.godownId == gq.godownId) { { godownId = g.godownId; qty = g.qty + gq.qty } }
                else g
              });
            };
          };
        };
        inventory := Array.map(inventory, func(i : InventoryItem) : InventoryItem {
          if (i.id == inv.id) {
            { id = inv.id; businessId = inv.businessId; category = inv.category;
              itemName = inv.itemName; subCategory = inv.subCategory; godownQtys = merged;
              shopQty = inv.shopQty + item.shopQty;
              purchaseRate = item.purchaseRate; saleRate = item.saleRate; }
          } else i
        });
      };
    };
  };

  public query func getTransfers(businessId : Text) : async [TransferEntry] {
    Array.filter(transfers, func(t : TransferEntry) : Bool { t.businessId == businessId })
  };

  public func postTransfer(entry : TransferEntry) : async Text {
    seed();
    let inv = Array.find(inventory, func(i : InventoryItem) : Bool {
      i.businessId == entry.businessId and i.category == entry.category
        and i.itemName == entry.itemName and i.subCategory == entry.subCategory
    });
    switch (inv) {
      case null return "Item not found in inventory";
      case (?item) {
        if (entry.fromType == "godown") {
          let gq = Array.find(item.godownQtys, func(g : GodownQty) : Bool { g.godownId == entry.fromId });
          switch (gq) {
            case null  return "Godown not found";
            case (?g) {
              if (g.qty < entry.qty) return "Insufficient godown stock";
              let newGodownQtys = Array.map(item.godownQtys, func(g2 : GodownQty) : GodownQty {
                if (g2.godownId == entry.fromId) { { godownId = g2.godownId; qty = g2.qty - entry.qty } }
                else g2
              });
              let updated : InventoryItem = {
                id = item.id; businessId = item.businessId; category = item.category;
                itemName = item.itemName; subCategory = item.subCategory;
                godownQtys = newGodownQtys; shopQty = item.shopQty + entry.qty;
                purchaseRate = item.purchaseRate; saleRate = item.saleRate;
              };
              inventory := Array.map(inventory, func(i : InventoryItem) : InventoryItem {
                if (i.id == item.id) updated else i
              });
            };
          };
        } else {
          if (item.shopQty < entry.qty) return "Insufficient shop stock";
          let newGodownQtys = Array.map(item.godownQtys, func(g : GodownQty) : GodownQty {
            if (g.godownId == entry.toId) { { godownId = g.godownId; qty = g.qty + entry.qty } }
            else g
          });
          let updated : InventoryItem = {
            id = item.id; businessId = item.businessId; category = item.category;
            itemName = item.itemName; subCategory = item.subCategory;
            godownQtys = newGodownQtys; shopQty = item.shopQty - entry.qty;
            purchaseRate = item.purchaseRate; saleRate = item.saleRate;
          };
          inventory := Array.map(inventory, func(i : InventoryItem) : InventoryItem {
            if (i.id == item.id) updated else i
          });
        };
        transfers := Array.append(transfers, [entry]);
        let tx : TxRecord = {
          id = entry.id; businessId = entry.businessId; txType = #transfer;
          biltyNumber = ""; category = entry.category; itemName = entry.itemName;
          subCategory = entry.subCategory;
          fromLocation = entry.fromType # ":" # entry.fromId;
          toLocation   = entry.toType   # ":" # entry.toId;
          transport = ""; qty = entry.qty; rate = entry.rate;
          enteredBy = entry.transferredBy; notes = "transfer"; createdAt = entry.createdAt;
        };
        txHistory := Array.append(txHistory, [tx]);
        return "ok";
      };
    };
  };

  public query func getDeliveries(businessId : Text) : async [DeliveryEntry] {
    Array.filter(deliveries, func(d : DeliveryEntry) : Bool { d.businessId == businessId })
  };

  public func addDelivery(entry : DeliveryEntry) : async Text {
    seed();
    for (item in entry.items.vals()) {
      let inv = Array.find(inventory, func(i : InventoryItem) : Bool {
        i.businessId == entry.businessId and i.category == item.category
          and i.itemName == item.itemName and i.subCategory == item.subCategory
      });
      switch (inv) {
        case null {};
        case (?existing) {
          let gq = Array.find(existing.godownQtys, func(g : GodownQty) : Bool { g.godownId == item.godownId });
          switch (gq) {
            case null {};
            case (?g) {
              if (g.qty < item.qty) return "Insufficient stock in godown";
              let newGodownQtys = Array.map(existing.godownQtys, func(g2 : GodownQty) : GodownQty {
                if (g2.godownId == item.godownId) { { godownId = g2.godownId; qty = g2.qty - item.qty } }
                else g2
              });
              let updated : InventoryItem = {
                id = existing.id; businessId = existing.businessId; category = existing.category;
                itemName = existing.itemName; subCategory = existing.subCategory;
                godownQtys = newGodownQtys; shopQty = existing.shopQty + item.qty;
                purchaseRate = existing.purchaseRate; saleRate = existing.saleRate;
              };
              inventory := Array.map(inventory, func(i : InventoryItem) : InventoryItem {
                if (i.id == existing.id) updated else i
              });
            };
          };
        };
      };
      let tx : TxRecord = {
        id = entry.id # "-" # item.itemName; businessId = entry.businessId; txType = #delivery;
        biltyNumber = entry.biltyNumber; category = item.category; itemName = item.itemName;
        subCategory = item.subCategory; fromLocation = item.godownId; toLocation = entry.customerName;
        transport = ""; qty = item.qty; rate = 0.0; enteredBy = entry.deliveredBy;
        notes = entry.customerPhone; createdAt = entry.createdAt;
      };
      txHistory := Array.append(txHistory, [tx]);
    };
    deliveries := Array.append(deliveries, [entry]);
    if (entry.deliveryType == "queue" and entry.biltyNumber != "") {
      queueEntries := Array.map(queueEntries, func(e : QueueEntry) : QueueEntry {
        if (e.biltyNumber == entry.biltyNumber) {
          { id = e.id; biltyNumber = e.biltyNumber; transport = e.transport;
            supplier = e.supplier; bales = e.bales; businessId = e.businessId;
            enteredBy = e.enteredBy; createdAt = e.createdAt; delivered = true }
        } else e
      });
    };
    "ok"
  };

  public query func getSales(businessId : Text) : async [SaleEntry] {
    Array.filter(sales, func(s : SaleEntry) : Bool { s.businessId == businessId })
  };

  public func addSale(entry : SaleEntry) : async Text {
    seed();
    for (item in entry.items.vals()) {
      let inv = Array.find(inventory, func(i : InventoryItem) : Bool {
        i.businessId == entry.businessId and i.category == item.category
          and i.itemName == item.itemName and i.subCategory == item.subCategory
      });
      switch (inv) {
        case null return "Item not found: " # item.itemName;
        case (?existing) {
          if (existing.shopQty < item.qty) return "Insufficient shop stock for: " # item.itemName;
          let updated : InventoryItem = {
            id = existing.id; businessId = existing.businessId; category = existing.category;
            itemName = existing.itemName; subCategory = existing.subCategory;
            godownQtys = existing.godownQtys; shopQty = existing.shopQty - item.qty;
            purchaseRate = existing.purchaseRate; saleRate = item.rate;
          };
          inventory := Array.map(inventory, func(i : InventoryItem) : InventoryItem {
            if (i.id == existing.id) updated else i
          });
        };
      };
      let tx : TxRecord = {
        id = entry.id # "-" # item.itemName; businessId = entry.businessId; txType = #sale;
        biltyNumber = ""; category = item.category; itemName = item.itemName;
        subCategory = item.subCategory; fromLocation = "Shop"; toLocation = "Customer";
        transport = ""; qty = item.qty; rate = item.rate; enteredBy = entry.recordedBy;
        notes = "sale"; createdAt = entry.createdAt;
      };
      txHistory := Array.append(txHistory, [tx]);
    };
    sales := Array.append(sales, [entry]);
    "ok"
  };

  public query func getTxHistory(businessId : Text) : async [TxRecord] {
    Array.filter(txHistory, func(t : TxRecord) : Bool { t.businessId == businessId })
  };

  public func addTxRecord(record : TxRecord) : async () {
    seed(); txHistory := Array.append(txHistory, [record]);
  };

  public func deleteTxRecord(id : Text) : async () {
    txHistory := Array.filter(txHistory, func(t : TxRecord) : Bool { t.id != id });
  };


  public func saveAppSettings(json : Text) : async () {
    appSettings := json;
  };

  public query func getAppSettings() : async Text {
    appSettings
  };

  public shared ({ caller }) func getCurrentUser() : async Text {
    caller.toText()
  };

};
