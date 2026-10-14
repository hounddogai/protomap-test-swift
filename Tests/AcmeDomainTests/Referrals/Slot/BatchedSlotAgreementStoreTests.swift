@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryBatchedSlotAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.BatchedSlotAgreementStore = Referrals.newMemoryBatchedSlotAgreementStore()
        let item = Referrals.newBatchedSlotAgreement("code-870", title: "title-100")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
