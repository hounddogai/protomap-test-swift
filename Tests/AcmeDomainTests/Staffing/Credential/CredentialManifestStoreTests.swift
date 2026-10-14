@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryCredentialManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.CredentialManifestStore = Staffing.newMemoryCredentialManifestStore()
        let item = Staffing.newCredentialManifest("code-776", name: "name-503")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
