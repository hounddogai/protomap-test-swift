@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingStatementExceptionTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newRollingStatementException("code-543", name: "name-16")
        #expect(item.status == RevenueCycle.RollingStatementExceptionStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = RevenueCycle.newRollingStatementException("code-543", name: "name-16")
        try item.moveTo(RevenueCycle.RollingStatementExceptionStatus.running)
        #expect(item.status == RevenueCycle.RollingStatementExceptionStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newRollingStatementException("code-543", name: "name-16")
        item.status = RevenueCycle.RollingStatementExceptionStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RollingStatementExceptionStatus.new) }
    }
}
