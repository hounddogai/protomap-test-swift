@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInventoryBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InventoryBaselineStore = Pharmacy.newMemoryInventoryBaselineStore()
        let item = Pharmacy.newInventoryBaseline("code-504", label: "label-969")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
