@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFollowUpCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FollowUpCycleStore = Referrals.newMemoryFollowUpCycleStore()
        let item = Referrals.newFollowUpCycle("code-827", label: "label-429")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
