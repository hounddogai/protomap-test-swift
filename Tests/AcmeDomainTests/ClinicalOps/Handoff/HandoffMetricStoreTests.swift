@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryHandoffMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.HandoffMetricStore = ClinicalOps.newMemoryHandoffMetricStore()
        let item = ClinicalOps.newHandoffMetric("code-334", label: "label-400")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
