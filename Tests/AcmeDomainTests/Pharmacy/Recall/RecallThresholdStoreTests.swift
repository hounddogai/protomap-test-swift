@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRecallThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RecallThresholdStore = Pharmacy.newMemoryRecallThresholdStore()
        let item = Pharmacy.newRecallThreshold("code-124", name: "name-154")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
