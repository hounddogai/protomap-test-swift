@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemorySkillMixManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.SkillMixManifestStore = Staffing.newMemorySkillMixManifestStore()
        let item = Staffing.newSkillMixManifest("code-629", name: "name-458")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
