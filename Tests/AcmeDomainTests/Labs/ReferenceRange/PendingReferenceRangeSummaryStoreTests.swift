@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPendingReferenceRangeSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PendingReferenceRangeSummaryStore = Labs.newMemoryPendingReferenceRangeSummaryStore()
        let item = Labs.newPendingReferenceRangeSummary("code-140", title: "title-438")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
