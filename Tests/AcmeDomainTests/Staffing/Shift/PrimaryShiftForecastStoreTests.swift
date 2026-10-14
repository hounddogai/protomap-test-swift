@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryPrimaryShiftForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.PrimaryShiftForecastStore = Staffing.newMemoryPrimaryShiftForecastStore()
        let item = Staffing.newPrimaryShiftForecast("code-469", label: "label-951")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
