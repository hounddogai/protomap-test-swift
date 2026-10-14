@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCourierReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CourierReviewStore = Labs.newMemoryCourierReviewStore()
        let item = Labs.newCourierReview("code-625", name: "name-631")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
