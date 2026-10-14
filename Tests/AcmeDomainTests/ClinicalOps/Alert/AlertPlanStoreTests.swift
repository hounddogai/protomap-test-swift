@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAlertPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AlertPlanStore = ClinicalOps.newMemoryAlertPlanStore()
        let item = ClinicalOps.newAlertPlan("code-966", title: "title-15")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
