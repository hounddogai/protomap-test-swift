@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFollowUpDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FollowUpDigestStore = Referrals.newMemoryFollowUpDigestStore()
        let item = Referrals.newFollowUpDigest("code-724", label: "label-306")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
