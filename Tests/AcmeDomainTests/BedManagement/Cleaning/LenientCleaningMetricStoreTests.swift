@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryLenientCleaningMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.LenientCleaningMetricStore = BedManagement.newMemoryLenientCleaningMetricStore()
        let item = BedManagement.newLenientCleaningMetric("code-866", title: "title-738")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
