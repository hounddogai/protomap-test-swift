@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryTieredFollowUpManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.TieredFollowUpManifestStore = Referrals.newMemoryTieredFollowUpManifestStore()
        let item = Referrals.newTieredFollowUpManifest("code-588", label: "label-767")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
