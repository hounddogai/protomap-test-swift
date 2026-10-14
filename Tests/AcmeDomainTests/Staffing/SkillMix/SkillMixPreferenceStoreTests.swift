@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemorySkillMixPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.SkillMixPreferenceStore = Staffing.newMemorySkillMixPreferenceStore()
        let item = Staffing.newSkillMixPreference("code-449", label: "label-404")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
