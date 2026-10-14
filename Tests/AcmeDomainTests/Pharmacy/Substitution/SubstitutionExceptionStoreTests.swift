@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemorySubstitutionExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.SubstitutionExceptionStore = Pharmacy.newMemorySubstitutionExceptionStore()
        let item = Pharmacy.newSubstitutionException("code-510", title: "title-39")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
