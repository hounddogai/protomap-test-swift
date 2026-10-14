@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryAdaptiveStatementReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.AdaptiveStatementReservationStore = RevenueCycle.newMemoryAdaptiveStatementReservationStore()
        let item = RevenueCycle.newAdaptiveStatementReservation("code-449", name: "name-317")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
