@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryLenientSubstitutionTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.LenientSubstitutionTierStore = Pharmacy.newMemoryLenientSubstitutionTierStore()
        let item = Pharmacy.newLenientSubstitutionTier("code-257", title: "title-370")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
