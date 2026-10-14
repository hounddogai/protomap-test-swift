@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryFallbackDischargePlanMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.FallbackDischargePlanMetricStore = BedManagement.newMemoryFallbackDischargePlanMetricStore()
        let item = BedManagement.newFallbackDischargePlanMetric("code-87", label: "label-580")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
