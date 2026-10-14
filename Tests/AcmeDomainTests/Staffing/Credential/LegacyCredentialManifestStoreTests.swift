@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryLegacyCredentialManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.LegacyCredentialManifestStore = Staffing.newMemoryLegacyCredentialManifestStore()
        let item = Staffing.newLegacyCredentialManifest("code-545", title: "title-612")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
