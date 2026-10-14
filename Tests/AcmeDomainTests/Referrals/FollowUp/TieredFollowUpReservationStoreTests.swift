@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryTieredFollowUpReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.TieredFollowUpReservationStore = Referrals.newMemoryTieredFollowUpReservationStore()
        let item = Referrals.newTieredFollowUpReservation("code-173", label: "label-886")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
