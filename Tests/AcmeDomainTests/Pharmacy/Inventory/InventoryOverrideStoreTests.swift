@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInventoryOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InventoryOverrideStore = Pharmacy.newMemoryInventoryOverrideStore()
        let item = Pharmacy.newInventoryOverride("code-588", title: "title-790")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
