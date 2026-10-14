@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryRollingReferralScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.RollingReferralScoreStore = Referrals.newMemoryRollingReferralScoreStore()
        let item = Referrals.newRollingReferralScore("code-562", label: "label-379")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
