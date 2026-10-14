@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryFallbackSkillMixTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.FallbackSkillMixTemplateStore = Staffing.newMemoryFallbackSkillMixTemplateStore()
        let item = Staffing.newFallbackSkillMixTemplate("code-447", label: "label-132")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
