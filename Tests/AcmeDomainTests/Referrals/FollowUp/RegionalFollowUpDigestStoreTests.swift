@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryRegionalFollowUpDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.RegionalFollowUpDigestStore = Referrals.newMemoryRegionalFollowUpDigestStore()
        let item = Referrals.newRegionalFollowUpDigest("code-780", title: "title-644")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
