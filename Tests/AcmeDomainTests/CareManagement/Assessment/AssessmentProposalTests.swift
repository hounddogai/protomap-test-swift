@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentProposalTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newAssessmentProposal("code-683", title: "title-104")
        #expect(item.status == CareManagement.AssessmentProposalStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = CareManagement.newAssessmentProposal("code-683", title: "title-104")
        try item.moveTo(CareManagement.AssessmentProposalStatus.inProgress)
        #expect(item.status == CareManagement.AssessmentProposalStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newAssessmentProposal("code-683", title: "title-104")
        item.status = CareManagement.AssessmentProposalStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AssessmentProposalStatus.planned) }
    }
}
