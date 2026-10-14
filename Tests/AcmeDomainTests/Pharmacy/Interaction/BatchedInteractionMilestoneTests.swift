@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedInteractionMilestoneTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newBatchedInteractionMilestone("code-965", name: "name-516")
        #expect(item.status == Pharmacy.BatchedInteractionMilestoneStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Pharmacy.newBatchedInteractionMilestone("code-965", name: "name-516")
        try item.moveTo(Pharmacy.BatchedInteractionMilestoneStatus.stopped)
        #expect(item.status == Pharmacy.BatchedInteractionMilestoneStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newBatchedInteractionMilestone("code-965", name: "name-516")
        item.status = Pharmacy.BatchedInteractionMilestoneStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.BatchedInteractionMilestoneStatus.idle) }
    }
}
