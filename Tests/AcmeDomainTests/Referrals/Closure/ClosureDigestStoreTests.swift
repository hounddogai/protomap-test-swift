@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryClosureDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ClosureDigestStore = Referrals.newMemoryClosureDigestStore()
        let item = Referrals.newClosureDigest("code-214", label: "label-507")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
