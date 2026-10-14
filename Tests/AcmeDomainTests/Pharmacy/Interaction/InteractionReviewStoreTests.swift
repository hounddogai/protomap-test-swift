@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInteractionReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InteractionReviewStore = Pharmacy.newMemoryInteractionReviewStore()
        let item = Pharmacy.newInteractionReview("code-84", label: "label-306")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
