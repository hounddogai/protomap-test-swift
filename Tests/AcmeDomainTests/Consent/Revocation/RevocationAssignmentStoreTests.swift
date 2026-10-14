@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRevocationAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RevocationAssignmentStore = Consent.newMemoryRevocationAssignmentStore()
        let item = Consent.newRevocationAssignment("code-942", name: "name-913")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
