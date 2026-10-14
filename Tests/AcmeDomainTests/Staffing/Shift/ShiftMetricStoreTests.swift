@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryShiftMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.ShiftMetricStore = Staffing.newMemoryShiftMetricStore()
        let item = Staffing.newShiftMetric("code-613", label: "label-449")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
