@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryAdaptiveDispenseReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.AdaptiveDispenseReviewStore = Pharmacy.newMemoryAdaptiveDispenseReviewStore()
        let item = Pharmacy.newAdaptiveDispenseReview("code-906", label: "label-529")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
