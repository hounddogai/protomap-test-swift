@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemorySubstitutionBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.SubstitutionBaselineStore = Pharmacy.newMemorySubstitutionBaselineStore()
        let item = Pharmacy.newSubstitutionBaseline("code-688", title: "title-927")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
