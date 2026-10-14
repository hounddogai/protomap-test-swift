@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryWeightedRecallDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.WeightedRecallDraftStore = Pharmacy.newMemoryWeightedRecallDraftStore()
        let item = Pharmacy.newWeightedRecallDraft("code-807", name: "name-632")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
