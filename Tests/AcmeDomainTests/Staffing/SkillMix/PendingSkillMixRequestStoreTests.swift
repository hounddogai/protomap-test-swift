@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryPendingSkillMixRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.PendingSkillMixRequestStore = Staffing.newMemoryPendingSkillMixRequestStore()
        let item = Staffing.newPendingSkillMixRequest("code-279", name: "name-639")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
