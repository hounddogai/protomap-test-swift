@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryFallbackAccessionReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.FallbackAccessionReviewStore = Labs.newMemoryFallbackAccessionReviewStore()
        let item = Labs.newFallbackAccessionReview("code-590", label: "label-212")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
