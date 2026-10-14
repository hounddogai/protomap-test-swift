@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryStrictSkillMixForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.StrictSkillMixForecastStore = Staffing.newMemoryStrictSkillMixForecastStore()
        let item = Staffing.newStrictSkillMixForecast("code-433", label: "label-917")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
