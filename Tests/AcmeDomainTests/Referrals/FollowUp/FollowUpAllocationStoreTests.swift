@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFollowUpAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FollowUpAllocationStore = Referrals.newMemoryFollowUpAllocationStore()
        let item = Referrals.newFollowUpAllocation("code-588", label: "label-276")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
