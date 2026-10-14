@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemorySkillMixRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.SkillMixRuleStore = Staffing.newMemorySkillMixRuleStore()
        let item = Staffing.newSkillMixRule("code-998", name: "name-735")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
