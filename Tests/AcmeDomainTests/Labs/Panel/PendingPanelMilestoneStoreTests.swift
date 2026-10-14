@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPendingPanelMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PendingPanelMilestoneStore = Labs.newMemoryPendingPanelMilestoneStore()
        let item = Labs.newPendingPanelMilestone("code-879", name: "name-483")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
