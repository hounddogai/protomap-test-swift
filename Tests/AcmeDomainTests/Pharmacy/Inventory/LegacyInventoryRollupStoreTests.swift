@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryLegacyInventoryRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.LegacyInventoryRollupStore = Pharmacy.newMemoryLegacyInventoryRollupStore()
        let item = Pharmacy.newLegacyInventoryRollup("code-352", label: "label-163")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
