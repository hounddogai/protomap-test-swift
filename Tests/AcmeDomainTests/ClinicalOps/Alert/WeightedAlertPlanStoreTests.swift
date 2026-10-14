@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryWeightedAlertPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.WeightedAlertPlanStore = ClinicalOps.newMemoryWeightedAlertPlanStore()
        let item = ClinicalOps.newWeightedAlertPlan("code-700", title: "title-331")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
