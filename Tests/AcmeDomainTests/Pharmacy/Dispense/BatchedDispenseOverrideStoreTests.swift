@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryBatchedDispenseOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.BatchedDispenseOverrideStore = Pharmacy.newMemoryBatchedDispenseOverrideStore()
        let item = Pharmacy.newBatchedDispenseOverride("code-785", name: "name-538")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
