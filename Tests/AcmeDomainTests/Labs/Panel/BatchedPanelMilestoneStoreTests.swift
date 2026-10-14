@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryBatchedPanelMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.BatchedPanelMilestoneStore = Labs.newMemoryBatchedPanelMilestoneStore()
        let item = Labs.newBatchedPanelMilestone("code-783", name: "name-647")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
