@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryCredentialPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.CredentialPolicyStore = Staffing.newMemoryCredentialPolicyStore()
        let item = Staffing.newCredentialPolicy("code-89", title: "title-409")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
