@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryCredentialGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.CredentialGroupStore = Staffing.newMemoryCredentialGroupStore()
        let item = Staffing.newCredentialGroup("code-288", name: "name-620")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
