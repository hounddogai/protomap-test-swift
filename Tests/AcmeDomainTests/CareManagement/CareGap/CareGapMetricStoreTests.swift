@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCareGapMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CareGapMetricStore = CareManagement.newMemoryCareGapMetricStore()
        let item = CareManagement.newCareGapMetric("code-496", title: "title-912")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
