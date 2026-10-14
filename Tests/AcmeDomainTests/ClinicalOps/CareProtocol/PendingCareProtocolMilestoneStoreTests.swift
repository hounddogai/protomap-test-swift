@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryPendingCareProtocolMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.PendingCareProtocolMilestoneStore = ClinicalOps.newMemoryPendingCareProtocolMilestoneStore()
        let item = ClinicalOps.newPendingCareProtocolMilestone("code-276", name: "name-439")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
