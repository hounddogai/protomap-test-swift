@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryCappedSkillMixCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.CappedSkillMixCycleStore = Staffing.newMemoryCappedSkillMixCycleStore()
        let item = Staffing.newCappedSkillMixCycle("code-602", title: "title-839")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
