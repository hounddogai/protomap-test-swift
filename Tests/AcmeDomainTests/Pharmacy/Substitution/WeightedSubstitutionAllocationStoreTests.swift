@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryWeightedSubstitutionAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.WeightedSubstitutionAllocationStore = Pharmacy.newMemoryWeightedSubstitutionAllocationStore()
        let item = Pharmacy.newWeightedSubstitutionAllocation("code-810", title: "title-169")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
