@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryManualNetworkAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ManualNetworkAgreementStore = Referrals.newMemoryManualNetworkAgreementStore()
        let item = Referrals.newManualNetworkAgreement("code-38", name: "name-486")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
