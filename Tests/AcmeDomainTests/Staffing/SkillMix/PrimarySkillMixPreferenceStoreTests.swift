@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryPrimarySkillMixPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.PrimarySkillMixPreferenceStore = Staffing.newMemoryPrimarySkillMixPreferenceStore()
        let item = Staffing.newPrimarySkillMixPreference("code-294", label: "label-440")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
