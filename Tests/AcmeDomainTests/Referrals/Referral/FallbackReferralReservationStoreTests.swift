@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFallbackReferralReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FallbackReferralReservationStore = Referrals.newMemoryFallbackReferralReservationStore()
        let item = Referrals.newFallbackReferralReservation("code-61", label: "label-959")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
