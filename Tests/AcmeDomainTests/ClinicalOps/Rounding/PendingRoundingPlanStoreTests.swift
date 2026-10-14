@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryPendingRoundingPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.PendingRoundingPlanStore = ClinicalOps.newMemoryPendingRoundingPlanStore()
        let item = ClinicalOps.newPendingRoundingPlan("code-978", title: "title-573")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
