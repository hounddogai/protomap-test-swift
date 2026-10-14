@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemorySeasonalReferralProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.SeasonalReferralProfileStore = Referrals.newMemorySeasonalReferralProfileStore()
        let item = Referrals.newSeasonalReferralProfile("code-21", label: "label-985")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
