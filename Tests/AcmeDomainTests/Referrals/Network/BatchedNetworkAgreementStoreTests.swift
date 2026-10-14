@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryBatchedNetworkAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.BatchedNetworkAgreementStore = Referrals.newMemoryBatchedNetworkAgreementStore()
        let item = Referrals.newBatchedNetworkAgreement("code-181", label: "label-145")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
