@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryBatchedPanelScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.BatchedPanelScoreStore = Labs.newMemoryBatchedPanelScoreStore()
        let item = Labs.newBatchedPanelScore("code-579", title: "title-376")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
