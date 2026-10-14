@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryCredentialExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.CredentialExceptionStore = Staffing.newMemoryCredentialExceptionStore()
        let item = Staffing.newCredentialException("code-790", title: "title-792")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
