@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRollingConsentFormReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RollingConsentFormReviewStore = Consent.newMemoryRollingConsentFormReviewStore()
        let item = Consent.newRollingConsentFormReview("code-581", title: "title-665")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
