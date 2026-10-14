@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInventoryTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InventoryTierStore = Pharmacy.newMemoryInventoryTierStore()
        let item = Pharmacy.newInventoryTier("code-231", label: "label-668")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
