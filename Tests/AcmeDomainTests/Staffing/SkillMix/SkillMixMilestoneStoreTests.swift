@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemorySkillMixMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.SkillMixMilestoneStore = Staffing.newMemorySkillMixMilestoneStore()
        let item = Staffing.newSkillMixMilestone("code-712", title: "title-771")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
