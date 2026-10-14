@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryEligibilityDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.EligibilityDigestStore = Referrals.newMemoryEligibilityDigestStore()
        let item = Referrals.newEligibilityDigest("code-720", label: "label-462")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
