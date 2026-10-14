@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultGoalProposalTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newDefaultGoalProposal("code-773", name: "name-810")
        #expect(item.status == CareManagement.DefaultGoalProposalStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = CareManagement.newDefaultGoalProposal("code-773", name: "name-810")
        try item.moveTo(CareManagement.DefaultGoalProposalStatus.queued)
        #expect(item.status == CareManagement.DefaultGoalProposalStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newDefaultGoalProposal("code-773", name: "name-810")
        item.status = CareManagement.DefaultGoalProposalStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.DefaultGoalProposalStatus.new) }
    }
}
