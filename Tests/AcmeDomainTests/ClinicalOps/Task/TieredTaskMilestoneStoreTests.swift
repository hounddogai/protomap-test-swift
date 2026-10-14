@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTieredTaskMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TieredTaskMilestoneStore = ClinicalOps.newMemoryTieredTaskMilestoneStore()
        let item = ClinicalOps.newTieredTaskMilestone("code-57", name: "name-112")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
