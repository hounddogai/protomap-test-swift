@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryScheduledDischargePlanForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.ScheduledDischargePlanForecastStore = BedManagement.newMemoryScheduledDischargePlanForecastStore()
        let item = BedManagement.newScheduledDischargePlanForecast("code-643", label: "label-170")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
