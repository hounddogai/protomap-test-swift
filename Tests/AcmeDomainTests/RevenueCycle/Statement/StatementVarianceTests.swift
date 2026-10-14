@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementVarianceTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newStatementVariance("code-670", label: "label-490")
        #expect(item.status == RevenueCycle.StatementVarianceStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = RevenueCycle.newStatementVariance("code-670", label: "label-490")
        try item.moveTo(RevenueCycle.StatementVarianceStatus.expired)
        #expect(item.status == RevenueCycle.StatementVarianceStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newStatementVariance("code-670", label: "label-490")
        item.status = RevenueCycle.StatementVarianceStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementVarianceStatus.requested) }
    }
}
