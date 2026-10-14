@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRecallSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RecallSummaryStore = Pharmacy.newMemoryRecallSummaryStore()
        let item = Pharmacy.newRecallSummary("code-918", title: "title-617")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
