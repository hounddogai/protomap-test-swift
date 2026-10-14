@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInventoryGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InventoryGroupStore = Pharmacy.newMemoryInventoryGroupStore()
        let item = Pharmacy.newInventoryGroup("code-387", label: "label-389")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
