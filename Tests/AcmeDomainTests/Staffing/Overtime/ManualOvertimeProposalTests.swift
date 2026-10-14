@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualOvertimeProposalTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newManualOvertimeProposal("code-5", name: "name-232")
        #expect(item.status == Staffing.ManualOvertimeProposalStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Staffing.newManualOvertimeProposal("code-5", name: "name-232")
        try item.moveTo(Staffing.ManualOvertimeProposalStatus.draining)
        #expect(item.status == Staffing.ManualOvertimeProposalStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newManualOvertimeProposal("code-5", name: "name-232")
        item.status = Staffing.ManualOvertimeProposalStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ManualOvertimeProposalStatus.idle) }
    }
}
