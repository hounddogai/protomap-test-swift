@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryCredentialClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.CredentialClaimStore = Staffing.newMemoryCredentialClaimStore()
        let item = Staffing.newCredentialClaim("code-593", title: "title-701")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
