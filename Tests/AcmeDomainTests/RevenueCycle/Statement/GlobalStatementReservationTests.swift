@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalStatementReservationTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newGlobalStatementReservation("code-967", label: "label-602")
        #expect(item.status == RevenueCycle.GlobalStatementReservationStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = RevenueCycle.newGlobalStatementReservation("code-967", label: "label-602")
        try item.moveTo(RevenueCycle.GlobalStatementReservationStatus.running)
        #expect(item.status == RevenueCycle.GlobalStatementReservationStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newGlobalStatementReservation("code-967", label: "label-602")
        item.status = RevenueCycle.GlobalStatementReservationStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.GlobalStatementReservationStatus.new) }
    }
}
