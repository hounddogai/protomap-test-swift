@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryManualEligibilityManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ManualEligibilityManifestStore = Referrals.newMemoryManualEligibilityManifestStore()
        let item = Referrals.newManualEligibilityManifest("code-134", title: "title-590")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
