@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemorySlotAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.SlotAgreementStore = Referrals.newMemorySlotAgreementStore()
        let item = Referrals.newSlotAgreement("code-100", label: "label-649")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
