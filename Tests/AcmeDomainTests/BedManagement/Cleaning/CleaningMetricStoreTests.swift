@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCleaningMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CleaningMetricStore = BedManagement.newMemoryCleaningMetricStore()
        let item = BedManagement.newCleaningMetric("code-211", title: "title-519")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
