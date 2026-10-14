@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemorySeasonalSkillMixPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.SeasonalSkillMixPlanStore = Staffing.newMemorySeasonalSkillMixPlanStore()
        let item = Staffing.newSeasonalSkillMixPlan("code-319", label: "label-564")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
