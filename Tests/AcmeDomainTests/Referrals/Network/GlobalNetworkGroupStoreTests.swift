@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryGlobalNetworkGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.GlobalNetworkGroupStore = Referrals.newMemoryGlobalNetworkGroupStore()
        let item = Referrals.newGlobalNetworkGroup("code-712", label: "label-838")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
