@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryLenientFollowUpTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.LenientFollowUpTargetStore = Referrals.newMemoryLenientFollowUpTargetStore()
        let item = Referrals.newLenientFollowUpTarget("code-543", title: "title-986")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
