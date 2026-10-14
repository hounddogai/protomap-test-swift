@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRegionalInventoryRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RegionalInventoryRollupStore = Pharmacy.newMemoryRegionalInventoryRollupStore()
        let item = Pharmacy.newRegionalInventoryRollup("code-364", label: "label-587")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
