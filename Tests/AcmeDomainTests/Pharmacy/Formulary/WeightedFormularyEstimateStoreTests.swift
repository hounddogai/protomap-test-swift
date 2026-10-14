@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryWeightedFormularyEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.WeightedFormularyEstimateStore = Pharmacy.newMemoryWeightedFormularyEstimateStore()
        let item = Pharmacy.newWeightedFormularyEstimate("code-985", label: "label-113")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
