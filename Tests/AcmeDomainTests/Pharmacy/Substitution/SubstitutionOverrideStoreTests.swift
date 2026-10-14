@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemorySubstitutionOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.SubstitutionOverrideStore = Pharmacy.newMemorySubstitutionOverrideStore()
        let item = Pharmacy.newSubstitutionOverride("code-249", name: "name-636")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
