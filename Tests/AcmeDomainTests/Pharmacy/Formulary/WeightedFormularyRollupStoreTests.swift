@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryWeightedFormularyRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.WeightedFormularyRollupStore = Pharmacy.newMemoryWeightedFormularyRollupStore()
        let item = Pharmacy.newWeightedFormularyRollup("code-1", name: "name-280")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
