@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryPendingHandoffPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.PendingHandoffPlanStore = ClinicalOps.newMemoryPendingHandoffPlanStore()
        let item = ClinicalOps.newPendingHandoffPlan("code-221", label: "label-371")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
