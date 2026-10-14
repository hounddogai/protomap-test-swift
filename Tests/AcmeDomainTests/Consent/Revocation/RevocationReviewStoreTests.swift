@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRevocationReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RevocationReviewStore = Consent.newMemoryRevocationReviewStore()
        let item = Consent.newRevocationReview("code-941", title: "title-478")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
