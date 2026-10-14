@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryConsentFormTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ConsentFormTierStore = Consent.newMemoryConsentFormTierStore()
        let item = Consent.newConsentFormTier("code-79", title: "title-443")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
