@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryCappedSubstitutionBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.CappedSubstitutionBaselineStore = Pharmacy.newMemoryCappedSubstitutionBaselineStore()
        let item = Pharmacy.newCappedSubstitutionBaseline("code-507", name: "name-945")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
