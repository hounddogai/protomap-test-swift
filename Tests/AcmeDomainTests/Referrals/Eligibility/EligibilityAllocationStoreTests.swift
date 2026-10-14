@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryEligibilityAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.EligibilityAllocationStore = Referrals.newMemoryEligibilityAllocationStore()
        let item = Referrals.newEligibilityAllocation("code-567", title: "title-200")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
