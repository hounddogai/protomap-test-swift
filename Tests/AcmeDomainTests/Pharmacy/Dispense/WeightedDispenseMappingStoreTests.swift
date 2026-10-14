@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryWeightedDispenseMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.WeightedDispenseMappingStore = Pharmacy.newMemoryWeightedDispenseMappingStore()
        let item = Pharmacy.newWeightedDispenseMapping("code-167", label: "label-924")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
