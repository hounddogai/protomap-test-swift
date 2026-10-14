@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryGlobalRecallSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.GlobalRecallSummaryStore = Pharmacy.newMemoryGlobalRecallSummaryStore()
        let item = Pharmacy.newGlobalRecallSummary("code-290", title: "title-746")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
