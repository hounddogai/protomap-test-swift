@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledOvertimeProposalTests {
    @Test func startsInNew() throws {
        let item = Staffing.newScheduledOvertimeProposal("code-498", label: "label-785")
        #expect(item.status == Staffing.ScheduledOvertimeProposalStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Staffing.newScheduledOvertimeProposal("code-498", label: "label-785")
        try item.moveTo(Staffing.ScheduledOvertimeProposalStatus.running)
        #expect(item.status == Staffing.ScheduledOvertimeProposalStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newScheduledOvertimeProposal("code-498", label: "label-785")
        item.status = Staffing.ScheduledOvertimeProposalStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ScheduledOvertimeProposalStatus.new) }
    }
}
