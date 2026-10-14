@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryDefaultSkillMixAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.DefaultSkillMixAssignmentStore = Staffing.newMemoryDefaultSkillMixAssignmentStore()
        let item = Staffing.newDefaultSkillMixAssignment("code-550", name: "name-80")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
