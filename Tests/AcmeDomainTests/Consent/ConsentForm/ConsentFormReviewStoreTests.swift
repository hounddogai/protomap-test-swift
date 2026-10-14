@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryConsentFormReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ConsentFormReviewStore = Consent.newMemoryConsentFormReviewStore()
        let item = Consent.newConsentFormReview("code-430", label: "label-3")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
