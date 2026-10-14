@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryDischargePlanMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.DischargePlanMetricStore = BedManagement.newMemoryDischargePlanMetricStore()
        let item = BedManagement.newDischargePlanMetric("code-99", title: "title-990")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
