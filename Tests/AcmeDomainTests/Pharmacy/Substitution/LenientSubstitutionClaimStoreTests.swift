@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryLenientSubstitutionClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.LenientSubstitutionClaimStore = Pharmacy.newMemoryLenientSubstitutionClaimStore()
        let item = Pharmacy.newLenientSubstitutionClaim("code-966", name: "name-323")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
