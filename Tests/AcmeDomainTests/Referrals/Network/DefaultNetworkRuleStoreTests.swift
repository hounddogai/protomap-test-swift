@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryDefaultNetworkRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.DefaultNetworkRuleStore = Referrals.newMemoryDefaultNetworkRuleStore()
        let item = Referrals.newDefaultNetworkRule("code-277", label: "label-953")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
