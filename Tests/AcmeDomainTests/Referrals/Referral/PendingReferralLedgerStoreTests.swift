@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryPendingReferralLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.PendingReferralLedgerStore = Referrals.newMemoryPendingReferralLedgerStore()
        let item = Referrals.newPendingReferralLedger("code-97", label: "label-68")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
