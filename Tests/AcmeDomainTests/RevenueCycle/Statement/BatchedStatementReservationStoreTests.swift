@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryBatchedStatementReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.BatchedStatementReservationStore = RevenueCycle.newMemoryBatchedStatementReservationStore()
        let item = RevenueCycle.newBatchedStatementReservation("code-733", label: "label-766")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
