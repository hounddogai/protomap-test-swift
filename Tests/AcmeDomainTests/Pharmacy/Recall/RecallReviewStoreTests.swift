@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRecallReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RecallReviewStore = Pharmacy.newMemoryRecallReviewStore()
        let item = Pharmacy.newRecallReview("code-565", name: "name-767")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
