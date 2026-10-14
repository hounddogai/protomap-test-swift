@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedStatementExceptionTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newCappedStatementException("code-493", label: "label-825")
        #expect(item.status == RevenueCycle.CappedStatementExceptionStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = RevenueCycle.newCappedStatementException("code-493", label: "label-825")
        try item.moveTo(RevenueCycle.CappedStatementExceptionStatus.validated)
        #expect(item.status == RevenueCycle.CappedStatementExceptionStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newCappedStatementException("code-493", label: "label-825")
        item.status = RevenueCycle.CappedStatementExceptionStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.CappedStatementExceptionStatus.created) }
    }
}
