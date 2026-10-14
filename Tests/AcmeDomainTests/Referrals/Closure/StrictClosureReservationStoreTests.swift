@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryStrictClosureReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.StrictClosureReservationStore = Referrals.newMemoryStrictClosureReservationStore()
        let item = Referrals.newStrictClosureReservation("code-38", label: "label-537")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
