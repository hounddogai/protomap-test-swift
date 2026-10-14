@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedAuthorizationTargetTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newBatchedAuthorizationTarget("code-359", name: "name-295")
        #expect(item.status == RevenueCycle.BatchedAuthorizationTargetStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = RevenueCycle.newBatchedAuthorizationTarget("code-359", name: "name-295")
        try item.moveTo(RevenueCycle.BatchedAuthorizationTargetStatus.inProgress)
        #expect(item.status == RevenueCycle.BatchedAuthorizationTargetStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newBatchedAuthorizationTarget("code-359", name: "name-295")
        item.status = RevenueCycle.BatchedAuthorizationTargetStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.BatchedAuthorizationTargetStatus.planned) }
    }
}
