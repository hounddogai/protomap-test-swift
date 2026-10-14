@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryAdaptiveTransferMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.AdaptiveTransferMetricStore = BedManagement.newMemoryAdaptiveTransferMetricStore()
        let item = BedManagement.newAdaptiveTransferMetric("code-100", title: "title-930")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
