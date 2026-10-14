@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryPendingSlotManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.PendingSlotManifestStore = Referrals.newMemoryPendingSlotManifestStore()
        let item = Referrals.newPendingSlotManifest("code-754", label: "label-929")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
