@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryRegionalEligibilityNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.RegionalEligibilityNoticeStore = Referrals.newMemoryRegionalEligibilityNoticeStore()
        let item = Referrals.newRegionalEligibilityNotice("code-844", title: "title-884")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
