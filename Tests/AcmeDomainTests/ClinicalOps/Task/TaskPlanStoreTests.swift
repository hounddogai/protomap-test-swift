@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTaskPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TaskPlanStore = ClinicalOps.newMemoryTaskPlanStore()
        let item = ClinicalOps.newTaskPlan("code-785", label: "label-708")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
