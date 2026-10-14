@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLenientProxyReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LenientProxyReviewStore = Consent.newMemoryLenientProxyReviewStore()
        let item = Consent.newLenientProxyReview("code-861", label: "label-575")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
