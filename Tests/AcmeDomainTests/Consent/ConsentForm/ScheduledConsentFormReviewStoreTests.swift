@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryScheduledConsentFormReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ScheduledConsentFormReviewStore = Consent.newMemoryScheduledConsentFormReviewStore()
        let item = Consent.newScheduledConsentFormReview("code-205", name: "name-823")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
