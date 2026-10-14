@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedRemittanceTargetTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newBatchedRemittanceTarget("code-120", title: "title-620")
        #expect(item.status == RevenueCycle.BatchedRemittanceTargetStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = RevenueCycle.newBatchedRemittanceTarget("code-120", title: "title-620")
        try item.moveTo(RevenueCycle.BatchedRemittanceTargetStatus.reopened)
        #expect(item.status == RevenueCycle.BatchedRemittanceTargetStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newBatchedRemittanceTarget("code-120", title: "title-620")
        item.status = RevenueCycle.BatchedRemittanceTargetStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.BatchedRemittanceTargetStatus.`open`) }
    }
}
