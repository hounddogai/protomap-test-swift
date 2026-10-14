@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryLegacySubstitutionClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.LegacySubstitutionClaimStore = Pharmacy.newMemoryLegacySubstitutionClaimStore()
        let item = Pharmacy.newLegacySubstitutionClaim("code-189", title: "title-177")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
