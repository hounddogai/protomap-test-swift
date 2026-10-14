@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryManualCareGapMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ManualCareGapMetricStore = CareManagement.newMemoryManualCareGapMetricStore()
        let item = CareManagement.newManualCareGapMetric("code-260", name: "name-483")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
