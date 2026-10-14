@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLanguageReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LanguageReviewStore = Consent.newMemoryLanguageReviewStore()
        let item = Consent.newLanguageReview("code-956", name: "name-771")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
