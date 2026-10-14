@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryRollingSlotAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.RollingSlotAgreementStore = Referrals.newMemoryRollingSlotAgreementStore()
        let item = Referrals.newRollingSlotAgreement("code-323", name: "name-513")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
