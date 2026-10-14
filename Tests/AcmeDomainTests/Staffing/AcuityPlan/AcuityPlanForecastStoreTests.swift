@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryAcuityPlanForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.AcuityPlanForecastStore = Staffing.newMemoryAcuityPlanForecastStore()
        let item = Staffing.newAcuityPlanForecast("code-499", title: "title-295")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
