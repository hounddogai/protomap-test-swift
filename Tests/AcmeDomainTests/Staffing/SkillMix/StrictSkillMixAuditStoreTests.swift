@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryStrictSkillMixAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.StrictSkillMixAuditStore = Staffing.newMemoryStrictSkillMixAuditStore()
        let item = Staffing.newStrictSkillMixAudit("code-759", name: "name-642")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
