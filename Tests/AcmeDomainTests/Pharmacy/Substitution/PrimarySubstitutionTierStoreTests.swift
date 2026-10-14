@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryPrimarySubstitutionTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.PrimarySubstitutionTierStore = Pharmacy.newMemoryPrimarySubstitutionTierStore()
        let item = Pharmacy.newPrimarySubstitutionTier("code-420", label: "label-366")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
