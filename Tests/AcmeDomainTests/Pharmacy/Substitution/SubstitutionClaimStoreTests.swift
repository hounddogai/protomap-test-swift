@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemorySubstitutionClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.SubstitutionClaimStore = Pharmacy.newMemorySubstitutionClaimStore()
        let item = Pharmacy.newSubstitutionClaim("code-623", label: "label-774")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
