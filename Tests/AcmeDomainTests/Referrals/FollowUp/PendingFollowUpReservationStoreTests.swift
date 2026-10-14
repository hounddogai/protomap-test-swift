@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryPendingFollowUpReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.PendingFollowUpReservationStore = Referrals.newMemoryPendingFollowUpReservationStore()
        let item = Referrals.newPendingFollowUpReservation("code-375", label: "label-87")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
