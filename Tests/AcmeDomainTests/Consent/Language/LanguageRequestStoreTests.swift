@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLanguageRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LanguageRequestStore = Consent.newMemoryLanguageRequestStore()
        let item = Consent.newLanguageRequest("code-115", title: "title-617")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
