@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryPendingFormularyReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.PendingFormularyReviewStore = Pharmacy.newMemoryPendingFormularyReviewStore()
        let item = Pharmacy.newPendingFormularyReview("code-328", name: "name-26")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
