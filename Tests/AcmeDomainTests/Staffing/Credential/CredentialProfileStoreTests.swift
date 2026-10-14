@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryCredentialProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.CredentialProfileStore = Staffing.newMemoryCredentialProfileStore()
        let item = Staffing.newCredentialProfile("code-589", title: "title-630")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
