@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemorySkillMixAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.SkillMixAssignmentStore = Staffing.newMemorySkillMixAssignmentStore()
        let item = Staffing.newSkillMixAssignment("code-888", name: "name-922")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
