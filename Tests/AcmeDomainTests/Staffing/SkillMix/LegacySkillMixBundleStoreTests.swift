@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryLegacySkillMixBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.LegacySkillMixBundleStore = Staffing.newMemoryLegacySkillMixBundleStore()
        let item = Staffing.newLegacySkillMixBundle("code-380", label: "label-25")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
