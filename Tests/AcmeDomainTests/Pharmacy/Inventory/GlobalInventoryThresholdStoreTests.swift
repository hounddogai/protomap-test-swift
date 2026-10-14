@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryGlobalInventoryThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.GlobalInventoryThresholdStore = Pharmacy.newMemoryGlobalInventoryThresholdStore()
        let item = Pharmacy.newGlobalInventoryThreshold("code-271", name: "name-66")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
