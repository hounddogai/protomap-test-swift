@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryLenientSkillMixAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.LenientSkillMixAssignmentStore = Staffing.newMemoryLenientSkillMixAssignmentStore()
        let item = Staffing.newLenientSkillMixAssignment("code-63", title: "title-469")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
