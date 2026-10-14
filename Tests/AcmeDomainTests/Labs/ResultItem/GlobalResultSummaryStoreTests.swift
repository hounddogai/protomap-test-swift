@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryGlobalResultSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.GlobalResultSummaryStore = Labs.newMemoryGlobalResultSummaryStore()
        let item = Labs.newGlobalResultSummary("code-368", label: "label-396")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
