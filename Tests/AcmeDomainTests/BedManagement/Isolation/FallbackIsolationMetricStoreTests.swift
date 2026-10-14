@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryFallbackIsolationMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.FallbackIsolationMetricStore = BedManagement.newMemoryFallbackIsolationMetricStore()
        let item = BedManagement.newFallbackIsolationMetric("code-725", title: "title-263")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
