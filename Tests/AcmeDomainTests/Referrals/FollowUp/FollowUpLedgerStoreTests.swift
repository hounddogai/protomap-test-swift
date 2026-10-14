@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFollowUpLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FollowUpLedgerStore = Referrals.newMemoryFollowUpLedgerStore()
        let item = Referrals.newFollowUpLedger("code-760", name: "name-677")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
