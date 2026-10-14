@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryPrimarySkillMixManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.PrimarySkillMixManifestStore = Staffing.newMemoryPrimarySkillMixManifestStore()
        let item = Staffing.newPrimarySkillMixManifest("code-621", title: "title-276")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
