@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInventoryReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InventoryReviewStore = Pharmacy.newMemoryInventoryReviewStore()
        let item = Pharmacy.newInventoryReview("code-473", name: "name-750")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
