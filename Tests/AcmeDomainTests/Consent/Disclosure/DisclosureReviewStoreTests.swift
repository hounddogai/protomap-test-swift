@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDisclosureReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DisclosureReviewStore = Consent.newMemoryDisclosureReviewStore()
        let item = Consent.newDisclosureReview("code-189", label: "label-208")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
