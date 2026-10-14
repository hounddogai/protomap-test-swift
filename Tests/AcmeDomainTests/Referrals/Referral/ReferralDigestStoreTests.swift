@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryReferralDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ReferralDigestStore = Referrals.newMemoryReferralDigestStore()
        let item = Referrals.newReferralDigest("code-99", label: "label-990")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
