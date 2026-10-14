@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryGlobalStatementReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.GlobalStatementReservationStore = RevenueCycle.newMemoryGlobalStatementReservationStore()
        let item = RevenueCycle.newGlobalStatementReservation("code-967", label: "label-602")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
