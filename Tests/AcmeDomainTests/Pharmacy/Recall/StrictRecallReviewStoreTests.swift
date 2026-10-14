@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryStrictRecallReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.StrictRecallReviewStore = Pharmacy.newMemoryStrictRecallReviewStore()
        let item = Pharmacy.newStrictRecallReview("code-784", label: "label-77")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
