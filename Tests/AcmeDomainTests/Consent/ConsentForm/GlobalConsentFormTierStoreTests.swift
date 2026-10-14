@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryGlobalConsentFormTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.GlobalConsentFormTierStore = Consent.newMemoryGlobalConsentFormTierStore()
        let item = Consent.newGlobalConsentFormTier("code-999", name: "name-348")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
