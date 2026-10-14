@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryPrimarySkillMixCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.PrimarySkillMixCycleStore = Staffing.newMemoryPrimarySkillMixCycleStore()
        let item = Staffing.newPrimarySkillMixCycle("code-375", name: "name-567")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
