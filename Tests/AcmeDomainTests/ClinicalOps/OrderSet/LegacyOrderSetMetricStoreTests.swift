@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryLegacyOrderSetMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.LegacyOrderSetMetricStore = ClinicalOps.newMemoryLegacyOrderSetMetricStore()
        let item = ClinicalOps.newLegacyOrderSetMetric("code-692", name: "name-378")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
