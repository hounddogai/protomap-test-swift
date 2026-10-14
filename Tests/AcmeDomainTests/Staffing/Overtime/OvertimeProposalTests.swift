@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeProposalTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newOvertimeProposal("code-964", name: "name-244")
        #expect(item.status == Staffing.OvertimeProposalStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Staffing.newOvertimeProposal("code-964", name: "name-244")
        try item.moveTo(Staffing.OvertimeProposalStatus.rejected)
        #expect(item.status == Staffing.OvertimeProposalStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newOvertimeProposal("code-964", name: "name-244")
        item.status = Staffing.OvertimeProposalStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimeProposalStatus.proposed) }
    }
}
