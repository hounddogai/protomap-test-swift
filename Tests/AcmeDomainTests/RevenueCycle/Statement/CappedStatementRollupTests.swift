@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedStatementRollupTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newCappedStatementRollup("code-745", name: "name-543")
        #expect(item.status == RevenueCycle.CappedStatementRollupStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = RevenueCycle.newCappedStatementRollup("code-745", name: "name-543")
        try item.moveTo(RevenueCycle.CappedStatementRollupStatus.revoked)
        #expect(item.status == RevenueCycle.CappedStatementRollupStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newCappedStatementRollup("code-745", name: "name-543")
        item.status = RevenueCycle.CappedStatementRollupStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.CappedStatementRollupStatus.requested) }
    }
}
