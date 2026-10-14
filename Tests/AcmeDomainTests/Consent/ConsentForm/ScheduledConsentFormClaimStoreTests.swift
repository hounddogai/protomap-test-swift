@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryScheduledConsentFormClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ScheduledConsentFormClaimStore = Consent.newMemoryScheduledConsentFormClaimStore()
        let item = Consent.newScheduledConsentFormClaim("code-443", title: "title-782")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
