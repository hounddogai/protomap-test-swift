@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryCappedDispenseReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.CappedDispenseReviewStore = Pharmacy.newMemoryCappedDispenseReviewStore()
        let item = Pharmacy.newCappedDispenseReview("code-411", label: "label-346")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
