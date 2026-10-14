@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveStatementReservationTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newAdaptiveStatementReservation("code-449", name: "name-317")
        #expect(item.status == RevenueCycle.AdaptiveStatementReservationStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = RevenueCycle.newAdaptiveStatementReservation("code-449", name: "name-317")
        try item.moveTo(RevenueCycle.AdaptiveStatementReservationStatus.queued)
        #expect(item.status == RevenueCycle.AdaptiveStatementReservationStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newAdaptiveStatementReservation("code-449", name: "name-317")
        item.status = RevenueCycle.AdaptiveStatementReservationStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AdaptiveStatementReservationStatus.new) }
    }
}
