@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeAssignmentTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newChargeAssignment("code-800", name: "name-404")
        #expect(item.status == RevenueCycle.ChargeAssignmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = RevenueCycle.newChargeAssignment("code-800", name: "name-404")
        try item.moveTo(RevenueCycle.ChargeAssignmentStatus.scheduled)
        #expect(item.status == RevenueCycle.ChargeAssignmentStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newChargeAssignment("code-800", name: "name-404")
        item.status = RevenueCycle.ChargeAssignmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargeAssignmentStatus.planned) }
    }
}
