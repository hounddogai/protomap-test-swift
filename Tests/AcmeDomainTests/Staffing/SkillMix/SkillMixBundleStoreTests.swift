@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemorySkillMixBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.SkillMixBundleStore = Staffing.newMemorySkillMixBundleStore()
        let item = Staffing.newSkillMixBundle("code-688", title: "title-609")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
