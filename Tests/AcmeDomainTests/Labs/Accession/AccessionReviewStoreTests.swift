@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAccessionReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AccessionReviewStore = Labs.newMemoryAccessionReviewStore()
        let item = Labs.newAccessionReview("code-966", name: "name-453")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
