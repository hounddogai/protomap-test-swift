@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryAdaptiveFollowUpNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.AdaptiveFollowUpNoticeStore = Referrals.newMemoryAdaptiveFollowUpNoticeStore()
        let item = Referrals.newAdaptiveFollowUpNotice("code-44", label: "label-559")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
