@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanProposalTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newAcuityPlanProposal("code-471", title: "title-612")
        #expect(item.status == Staffing.AcuityPlanProposalStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Staffing.newAcuityPlanProposal("code-471", title: "title-612")
        try item.moveTo(Staffing.AcuityPlanProposalStatus.pending)
        #expect(item.status == Staffing.AcuityPlanProposalStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newAcuityPlanProposal("code-471", title: "title-612")
        item.status = Staffing.AcuityPlanProposalStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanProposalStatus.draft) }
    }
}
