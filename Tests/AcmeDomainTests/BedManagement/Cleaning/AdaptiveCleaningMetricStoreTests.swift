@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryAdaptiveCleaningMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.AdaptiveCleaningMetricStore = BedManagement.newMemoryAdaptiveCleaningMetricStore()
        let item = BedManagement.newAdaptiveCleaningMetric("code-120", name: "name-750")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
