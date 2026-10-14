@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemorySubstitutionRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.SubstitutionRequestStore = Pharmacy.newMemorySubstitutionRequestStore()
        let item = Pharmacy.newSubstitutionRequest("code-911", title: "title-527")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
