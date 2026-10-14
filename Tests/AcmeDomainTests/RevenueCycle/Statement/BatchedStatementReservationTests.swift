@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedStatementReservationTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newBatchedStatementReservation("code-733", label: "label-766")
        #expect(item.status == RevenueCycle.BatchedStatementReservationStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = RevenueCycle.newBatchedStatementReservation("code-733", label: "label-766")
        try item.moveTo(RevenueCycle.BatchedStatementReservationStatus.queued)
        #expect(item.status == RevenueCycle.BatchedStatementReservationStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newBatchedStatementReservation("code-733", label: "label-766")
        item.status = RevenueCycle.BatchedStatementReservationStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.BatchedStatementReservationStatus.new) }
    }
}
