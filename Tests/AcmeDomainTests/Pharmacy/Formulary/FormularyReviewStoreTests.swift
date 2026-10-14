@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryFormularyReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.FormularyReviewStore = Pharmacy.newMemoryFormularyReviewStore()
        let item = Pharmacy.newFormularyReview("code-484", label: "label-565")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
