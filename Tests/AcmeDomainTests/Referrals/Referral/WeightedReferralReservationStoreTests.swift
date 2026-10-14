@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryWeightedReferralReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.WeightedReferralReservationStore = Referrals.newMemoryWeightedReferralReservationStore()
        let item = Referrals.newWeightedReferralReservation("code-339", title: "title-160")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
