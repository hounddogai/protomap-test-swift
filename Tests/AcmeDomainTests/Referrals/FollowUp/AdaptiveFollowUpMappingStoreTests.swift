@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryAdaptiveFollowUpMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.AdaptiveFollowUpMappingStore = Referrals.newMemoryAdaptiveFollowUpMappingStore()
        let item = Referrals.newAdaptiveFollowUpMapping("code-786", label: "label-632")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
