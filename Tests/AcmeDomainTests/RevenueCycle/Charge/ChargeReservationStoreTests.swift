@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryChargeReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ChargeReservationStore = RevenueCycle.newMemoryChargeReservationStore()
        let item = RevenueCycle.newChargeReservation("code-554", title: "title-803")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
