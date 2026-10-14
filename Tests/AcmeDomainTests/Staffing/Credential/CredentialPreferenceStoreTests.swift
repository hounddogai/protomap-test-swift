@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryCredentialPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.CredentialPreferenceStore = Staffing.newMemoryCredentialPreferenceStore()
        let item = Staffing.newCredentialPreference("code-374", name: "name-680")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
