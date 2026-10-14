@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryPrimaryConsentFormReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.PrimaryConsentFormReviewStore = Consent.newMemoryPrimaryConsentFormReviewStore()
        let item = Consent.newPrimaryConsentFormReview("code-466", title: "title-184")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
