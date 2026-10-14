@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryManualReferralMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ManualReferralMappingStore = Referrals.newMemoryManualReferralMappingStore()
        let item = Referrals.newManualReferralMapping("code-82", label: "label-380")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
