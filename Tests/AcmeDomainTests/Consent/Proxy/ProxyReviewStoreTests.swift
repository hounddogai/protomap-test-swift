@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryProxyReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ProxyReviewStore = Consent.newMemoryProxyReviewStore()
        let item = Consent.newProxyReview("code-595", name: "name-867")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
