@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryStrictLanguageAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.StrictLanguageAssignmentStore = Consent.newMemoryStrictLanguageAssignmentStore()
        let item = Consent.newStrictLanguageAssignment("code-192", title: "title-281")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
