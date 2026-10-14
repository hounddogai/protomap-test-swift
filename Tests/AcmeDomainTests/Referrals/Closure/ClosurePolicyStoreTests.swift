@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryClosurePolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ClosurePolicyStore = Referrals.newMemoryClosurePolicyStore()
        let item = Referrals.newClosurePolicy("code-347", label: "label-94")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
