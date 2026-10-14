@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemorySeasonalFormularyReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.SeasonalFormularyReviewStore = Pharmacy.newMemorySeasonalFormularyReviewStore()
        let item = Pharmacy.newSeasonalFormularyReview("code-466", title: "title-524")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
