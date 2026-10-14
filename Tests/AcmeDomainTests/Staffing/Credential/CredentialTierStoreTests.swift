@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryCredentialTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.CredentialTierStore = Staffing.newMemoryCredentialTierStore()
        let item = Staffing.newCredentialTier("code-350", name: "name-67")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
