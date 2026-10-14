@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryClosureAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ClosureAdjustmentStore = Referrals.newMemoryClosureAdjustmentStore()
        let item = Referrals.newClosureAdjustment("code-528", title: "title-234")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
