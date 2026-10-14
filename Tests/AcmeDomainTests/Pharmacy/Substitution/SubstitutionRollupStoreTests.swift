@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemorySubstitutionRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.SubstitutionRollupStore = Pharmacy.newMemorySubstitutionRollupStore()
        let item = Pharmacy.newSubstitutionRollup("code-777", name: "name-325")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
