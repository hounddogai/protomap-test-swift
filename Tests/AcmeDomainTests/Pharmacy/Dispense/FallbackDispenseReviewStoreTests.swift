@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryFallbackDispenseReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.FallbackDispenseReviewStore = Pharmacy.newMemoryFallbackDispenseReviewStore()
        let item = Pharmacy.newFallbackDispenseReview("code-425", title: "title-94")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
