@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLanguageAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LanguageAssignmentStore = Consent.newMemoryLanguageAssignmentStore()
        let item = Consent.newLanguageAssignment("code-554", name: "name-352")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
