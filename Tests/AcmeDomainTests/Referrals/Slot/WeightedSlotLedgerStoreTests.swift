@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryWeightedSlotLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.WeightedSlotLedgerStore = Referrals.newMemoryWeightedSlotLedgerStore()
        let item = Referrals.newWeightedSlotLedger("code-363", label: "label-801")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
