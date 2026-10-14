@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryFallbackConsentFormPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.FallbackConsentFormPolicyStore = Consent.newMemoryFallbackConsentFormPolicyStore()
        let item = Consent.newFallbackConsentFormPolicy("code-715", label: "label-887")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
