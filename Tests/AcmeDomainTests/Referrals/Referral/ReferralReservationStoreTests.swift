@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryReferralReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ReferralReservationStore = Referrals.newMemoryReferralReservationStore()
        let item = Referrals.newReferralReservation("code-294", label: "label-571")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
