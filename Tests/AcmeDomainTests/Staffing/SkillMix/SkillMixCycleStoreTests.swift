@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemorySkillMixCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.SkillMixCycleStore = Staffing.newMemorySkillMixCycleStore()
        let item = Staffing.newSkillMixCycle("code-433", label: "label-617")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
