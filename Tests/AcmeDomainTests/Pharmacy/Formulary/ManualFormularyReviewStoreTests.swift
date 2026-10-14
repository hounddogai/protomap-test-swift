@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryManualFormularyReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.ManualFormularyReviewStore = Pharmacy.newMemoryManualFormularyReviewStore()
        let item = Pharmacy.newManualFormularyReview("code-208", name: "name-99")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
