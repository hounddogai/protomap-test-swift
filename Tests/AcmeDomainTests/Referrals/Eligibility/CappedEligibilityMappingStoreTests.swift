@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryCappedEligibilityMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.CappedEligibilityMappingStore = Referrals.newMemoryCappedEligibilityMappingStore()
        let item = Referrals.newCappedEligibilityMapping("code-145", title: "title-858")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
