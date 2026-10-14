@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryResultSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ResultSummaryStore = Labs.newMemoryResultSummaryStore()
        let item = Labs.newResultSummary("code-534", label: "label-867")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
