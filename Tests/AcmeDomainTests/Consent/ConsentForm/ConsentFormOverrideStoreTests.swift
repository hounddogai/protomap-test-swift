@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryConsentFormOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ConsentFormOverrideStore = Consent.newMemoryConsentFormOverrideStore()
        let item = Consent.newConsentFormOverride("code-66", label: "label-474")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
