@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRemittanceReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RemittanceReservationStore = RevenueCycle.newMemoryRemittanceReservationStore()
        let item = RevenueCycle.newRemittanceReservation("code-888", label: "label-189")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
