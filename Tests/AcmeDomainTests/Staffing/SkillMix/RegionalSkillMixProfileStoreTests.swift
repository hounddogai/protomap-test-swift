@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryRegionalSkillMixProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.RegionalSkillMixProfileStore = Staffing.newMemoryRegionalSkillMixProfileStore()
        let item = Staffing.newRegionalSkillMixProfile("code-837", name: "name-892")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
