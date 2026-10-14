@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryLenientSlotDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.LenientSlotDigestStore = Referrals.newMemoryLenientSlotDigestStore()
        let item = Referrals.newLenientSlotDigest("code-959", title: "title-316")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
