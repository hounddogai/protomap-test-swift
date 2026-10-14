@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryEligibilityMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.EligibilityMappingStore = Referrals.newMemoryEligibilityMappingStore()
        let item = Referrals.newEligibilityMapping("code-7", name: "name-824")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
