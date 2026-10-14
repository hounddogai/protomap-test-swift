@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryWeightedRecallCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.WeightedRecallCycleStore = Pharmacy.newMemoryWeightedRecallCycleStore()
        let item = Pharmacy.newWeightedRecallCycle("code-7", name: "name-518")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
