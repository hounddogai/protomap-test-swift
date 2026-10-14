@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryGlobalClosureClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.GlobalClosureClaimStore = Referrals.newMemoryGlobalClosureClaimStore()
        let item = Referrals.newGlobalClosureClaim("code-719", title: "title-561")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
