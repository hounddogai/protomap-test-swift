@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryWeightedSubstitutionProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.WeightedSubstitutionProfileStore = Pharmacy.newMemoryWeightedSubstitutionProfileStore()
        let item = Pharmacy.newWeightedSubstitutionProfile("code-126", name: "name-264")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
