@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryWeightedFollowUpManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.WeightedFollowUpManifestStore = Referrals.newMemoryWeightedFollowUpManifestStore()
        let item = Referrals.newWeightedFollowUpManifest("code-762", title: "title-198")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
