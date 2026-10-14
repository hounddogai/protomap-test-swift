@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedDenialMilestoneTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newBatchedDenialMilestone("code-388", name: "name-349")
        #expect(item.status == RevenueCycle.BatchedDenialMilestoneStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = RevenueCycle.newBatchedDenialMilestone("code-388", name: "name-349")
        try item.moveTo(RevenueCycle.BatchedDenialMilestoneStatus.archived)
        #expect(item.status == RevenueCycle.BatchedDenialMilestoneStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newBatchedDenialMilestone("code-388", name: "name-349")
        item.status = RevenueCycle.BatchedDenialMilestoneStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.BatchedDenialMilestoneStatus.`open`) }
    }
}
