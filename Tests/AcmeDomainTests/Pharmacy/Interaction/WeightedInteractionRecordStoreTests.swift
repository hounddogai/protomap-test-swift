@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryWeightedInteractionRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.WeightedInteractionRecordStore = Pharmacy.newMemoryWeightedInteractionRecordStore()
        let item = Pharmacy.newWeightedInteractionRecord("code-721", title: "title-293")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
