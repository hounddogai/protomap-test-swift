@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryWeightedInteractionExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.WeightedInteractionExceptionStore = Pharmacy.newMemoryWeightedInteractionExceptionStore()
        let item = Pharmacy.newWeightedInteractionException("code-978", title: "title-994")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
