@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemorySkillMixDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.SkillMixDraftStore = Staffing.newMemorySkillMixDraftStore()
        let item = Staffing.newSkillMixDraft("code-288", name: "name-362")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
