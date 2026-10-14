@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalProposalTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newGoalProposal("code-991", title: "title-570")
        #expect(item.status == CareManagement.GoalProposalStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = CareManagement.newGoalProposal("code-991", title: "title-570")
        try item.moveTo(CareManagement.GoalProposalStatus.scheduled)
        #expect(item.status == CareManagement.GoalProposalStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newGoalProposal("code-991", title: "title-570")
        item.status = CareManagement.GoalProposalStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GoalProposalStatus.planned) }
    }
}
