@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFallbackReferralMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FallbackReferralMappingStore = Referrals.newMemoryFallbackReferralMappingStore()
        let item = Referrals.newFallbackReferralMapping("code-443", label: "label-475")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
