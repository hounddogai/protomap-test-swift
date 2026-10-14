@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryPrimaryLanguageAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.PrimaryLanguageAssignmentStore = Consent.newMemoryPrimaryLanguageAssignmentStore()
        let item = Consent.newPrimaryLanguageAssignment("code-882", name: "name-695")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
