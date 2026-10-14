@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementScheduleTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newStatementSchedule("code-461", label: "label-364")
        #expect(item.status == RevenueCycle.StatementScheduleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = RevenueCycle.newStatementSchedule("code-461", label: "label-364")
        try item.moveTo(RevenueCycle.StatementScheduleStatus.inProgress)
        #expect(item.status == RevenueCycle.StatementScheduleStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newStatementSchedule("code-461", label: "label-364")
        item.status = RevenueCycle.StatementScheduleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementScheduleStatus.planned) }
    }
}
