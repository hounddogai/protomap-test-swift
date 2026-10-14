@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryAdaptiveSkillMixManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.AdaptiveSkillMixManifestStore = Staffing.newMemoryAdaptiveSkillMixManifestStore()
        let item = Staffing.newAdaptiveSkillMixManifest("code-727", title: "title-991")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
