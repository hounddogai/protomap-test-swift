@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryWeightedRecallNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.WeightedRecallNoticeStore = Pharmacy.newMemoryWeightedRecallNoticeStore()
        let item = Pharmacy.newWeightedRecallNotice("code-341", label: "label-166")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
