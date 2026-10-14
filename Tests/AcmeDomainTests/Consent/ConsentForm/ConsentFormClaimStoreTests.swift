@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryConsentFormClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ConsentFormClaimStore = Consent.newMemoryConsentFormClaimStore()
        let item = Consent.newConsentFormClaim("code-795", label: "label-111")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
