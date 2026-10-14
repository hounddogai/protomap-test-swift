@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryClosureOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ClosureOverrideStore = Referrals.newMemoryClosureOverrideStore()
        let item = Referrals.newClosureOverride("code-510", label: "label-512")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
