@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemorySeasonalSkillMixForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.SeasonalSkillMixForecastStore = Staffing.newMemorySeasonalSkillMixForecastStore()
        let item = Staffing.newSeasonalSkillMixForecast("code-678", name: "name-961")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
