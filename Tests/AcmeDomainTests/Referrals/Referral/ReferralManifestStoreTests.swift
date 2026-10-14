@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryReferralManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ReferralManifestStore = Referrals.newMemoryReferralManifestStore()
        let item = Referrals.newReferralManifest("code-525", name: "name-102")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
