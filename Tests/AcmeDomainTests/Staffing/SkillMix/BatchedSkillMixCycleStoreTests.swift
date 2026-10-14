@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryBatchedSkillMixCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.BatchedSkillMixCycleStore = Staffing.newMemoryBatchedSkillMixCycleStore()
        let item = Staffing.newBatchedSkillMixCycle("code-713", title: "title-548")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
