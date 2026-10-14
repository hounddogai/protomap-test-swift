@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingStatementPreferenceTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newRollingStatementPreference("code-102", label: "label-148")
        #expect(item.status == RevenueCycle.RollingStatementPreferenceStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = RevenueCycle.newRollingStatementPreference("code-102", label: "label-148")
        try item.moveTo(RevenueCycle.RollingStatementPreferenceStatus.completed)
        #expect(item.status == RevenueCycle.RollingStatementPreferenceStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newRollingStatementPreference("code-102", label: "label-148")
        item.status = RevenueCycle.RollingStatementPreferenceStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RollingStatementPreferenceStatus.planned) }
    }
}
