@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryHandoffPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.HandoffPlanStore = ClinicalOps.newMemoryHandoffPlanStore()
        let item = ClinicalOps.newHandoffPlan("code-411", name: "name-88")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
