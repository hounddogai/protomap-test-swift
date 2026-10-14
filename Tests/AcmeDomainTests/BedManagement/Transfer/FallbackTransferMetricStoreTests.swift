@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryFallbackTransferMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.FallbackTransferMetricStore = BedManagement.newMemoryFallbackTransferMetricStore()
        let item = BedManagement.newFallbackTransferMetric("code-389", label: "label-580")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
