@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRollingSubstitutionClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RollingSubstitutionClaimStore = Pharmacy.newMemoryRollingSubstitutionClaimStore()
        let item = Pharmacy.newRollingSubstitutionClaim("code-745", title: "title-293")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
