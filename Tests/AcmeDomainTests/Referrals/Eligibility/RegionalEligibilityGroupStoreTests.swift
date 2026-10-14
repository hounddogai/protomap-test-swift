@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryRegionalEligibilityGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.RegionalEligibilityGroupStore = Referrals.newMemoryRegionalEligibilityGroupStore()
        let item = Referrals.newRegionalEligibilityGroup("code-723", label: "label-513")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
