@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryClosureBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ClosureBundleStore = Referrals.newMemoryClosureBundleStore()
        let item = Referrals.newClosureBundle("code-285", title: "title-726")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
