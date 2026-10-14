@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryBatchedTaskPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.BatchedTaskPlanStore = ClinicalOps.newMemoryBatchedTaskPlanStore()
        let item = ClinicalOps.newBatchedTaskPlan("code-562", label: "label-243")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
