@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingStatementTargetTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newPendingStatementTarget("code-24", name: "name-439")
        #expect(item.status == RevenueCycle.PendingStatementTargetStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = RevenueCycle.newPendingStatementTarget("code-24", name: "name-439")
        try item.moveTo(RevenueCycle.PendingStatementTargetStatus.cancelled)
        #expect(item.status == RevenueCycle.PendingStatementTargetStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newPendingStatementTarget("code-24", name: "name-439")
        item.status = RevenueCycle.PendingStatementTargetStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.PendingStatementTargetStatus.planned) }
    }
}
