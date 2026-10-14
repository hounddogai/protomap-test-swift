@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientGoalProposalTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newLenientGoalProposal("code-715", label: "label-520")
        #expect(item.status == CareManagement.LenientGoalProposalStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = CareManagement.newLenientGoalProposal("code-715", label: "label-520")
        try item.moveTo(CareManagement.LenientGoalProposalStatus.completed)
        #expect(item.status == CareManagement.LenientGoalProposalStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newLenientGoalProposal("code-715", label: "label-520")
        item.status = CareManagement.LenientGoalProposalStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.LenientGoalProposalStatus.planned) }
    }
}
