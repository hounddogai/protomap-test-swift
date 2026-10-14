@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryNetworkReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.NetworkReservationStore = Referrals.newMemoryNetworkReservationStore()
        let item = Referrals.newNetworkReservation("code-506", title: "title-989")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
