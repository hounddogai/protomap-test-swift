@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLanguageClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LanguageClaimStore = Consent.newMemoryLanguageClaimStore()
        let item = Consent.newLanguageClaim("code-422", label: "label-86")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
