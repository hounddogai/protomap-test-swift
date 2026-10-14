@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredOvertimeProposalTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newTieredOvertimeProposal("code-323", name: "name-841")
        #expect(item.status == Staffing.TieredOvertimeProposalStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Staffing.newTieredOvertimeProposal("code-323", name: "name-841")
        try item.moveTo(Staffing.TieredOvertimeProposalStatus.revoked)
        #expect(item.status == Staffing.TieredOvertimeProposalStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newTieredOvertimeProposal("code-323", name: "name-841")
        item.status = Staffing.TieredOvertimeProposalStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.TieredOvertimeProposalStatus.requested) }
    }
}
