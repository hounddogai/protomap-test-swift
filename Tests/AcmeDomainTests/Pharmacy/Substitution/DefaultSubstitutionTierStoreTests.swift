@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDefaultSubstitutionTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DefaultSubstitutionTierStore = Pharmacy.newMemoryDefaultSubstitutionTierStore()
        let item = Pharmacy.newDefaultSubstitutionTier("code-76", name: "name-40")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
