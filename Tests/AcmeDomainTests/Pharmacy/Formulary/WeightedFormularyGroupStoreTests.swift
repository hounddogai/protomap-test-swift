@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryWeightedFormularyGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.WeightedFormularyGroupStore = Pharmacy.newMemoryWeightedFormularyGroupStore()
        let item = Pharmacy.newWeightedFormularyGroup("code-709", label: "label-841")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
