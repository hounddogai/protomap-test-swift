@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryPrimaryAlertMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.PrimaryAlertMetricStore = ClinicalOps.newMemoryPrimaryAlertMetricStore()
        let item = ClinicalOps.newPrimaryAlertMetric("code-60", title: "title-982")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
