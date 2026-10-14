@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryClaimReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ClaimReservationStore = RevenueCycle.newMemoryClaimReservationStore()
        let item = RevenueCycle.newClaimReservation("code-370", label: "label-323")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
