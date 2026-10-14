@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryFallbackFormularyReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.FallbackFormularyReviewStore = Pharmacy.newMemoryFallbackFormularyReviewStore()
        let item = Pharmacy.newFallbackFormularyReview("code-408", name: "name-158")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
