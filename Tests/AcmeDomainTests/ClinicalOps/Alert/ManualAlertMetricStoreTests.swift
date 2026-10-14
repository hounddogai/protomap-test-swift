@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryManualAlertMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.ManualAlertMetricStore = ClinicalOps.newMemoryManualAlertMetricStore()
        let item = ClinicalOps.newManualAlertMetric("code-174", label: "label-920")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
