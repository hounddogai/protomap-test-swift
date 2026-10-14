@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryTieredReferralExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.TieredReferralExceptionStore = Referrals.newMemoryTieredReferralExceptionStore()
        let item = Referrals.newTieredReferralException("code-346", title: "title-112")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
