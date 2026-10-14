@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementReservationTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newStatementReservation("code-603", title: "title-206")
        #expect(item.status == RevenueCycle.StatementReservationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = RevenueCycle.newStatementReservation("code-603", title: "title-206")
        try item.moveTo(RevenueCycle.StatementReservationStatus.withdrawn)
        #expect(item.status == RevenueCycle.StatementReservationStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newStatementReservation("code-603", title: "title-206")
        item.status = RevenueCycle.StatementReservationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementReservationStatus.proposed) }
    }
}
