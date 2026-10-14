@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingWeightedAcuityPlanProposalTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newWeightedAcuityPlanProposal("code-691", label: "label-180")
        #expect(item.status == Staffing.WeightedAcuityPlanProposalStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Staffing.newWeightedAcuityPlanProposal("code-691", label: "label-180")
        try item.moveTo(Staffing.WeightedAcuityPlanProposalStatus.reopened)
        #expect(item.status == Staffing.WeightedAcuityPlanProposalStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newWeightedAcuityPlanProposal("code-691", label: "label-180")
        item.status = Staffing.WeightedAcuityPlanProposalStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.WeightedAcuityPlanProposalStatus.`open`) }
    }
}
