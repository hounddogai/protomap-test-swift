@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemorySkillMixProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.SkillMixProfileStore = Staffing.newMemorySkillMixProfileStore()
        let item = Staffing.newSkillMixProfile("code-216", name: "name-905")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
