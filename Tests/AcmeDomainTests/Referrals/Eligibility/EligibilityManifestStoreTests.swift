@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryEligibilityManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.EligibilityManifestStore = Referrals.newMemoryEligibilityManifestStore()
        let item = Referrals.newEligibilityManifest("code-196", title: "title-516")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
