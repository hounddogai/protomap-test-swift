@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryCappedFollowUpTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.CappedFollowUpTargetStore = Referrals.newMemoryCappedFollowUpTargetStore()
        let item = Referrals.newCappedFollowUpTarget("code-230", title: "title-79")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
