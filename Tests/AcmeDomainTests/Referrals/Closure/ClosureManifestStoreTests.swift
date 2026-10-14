@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryClosureManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ClosureManifestStore = Referrals.newMemoryClosureManifestStore()
        let item = Referrals.newClosureManifest("code-393", title: "title-335")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
