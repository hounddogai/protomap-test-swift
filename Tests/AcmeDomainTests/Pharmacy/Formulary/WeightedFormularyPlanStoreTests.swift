@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryWeightedFormularyPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.WeightedFormularyPlanStore = Pharmacy.newMemoryWeightedFormularyPlanStore()
        let item = Pharmacy.newWeightedFormularyPlan("code-664", label: "label-521")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
