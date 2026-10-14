@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolProposalTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newFloatPoolProposal("code-119", title: "title-735")
        #expect(item.status == Staffing.FloatPoolProposalStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Staffing.newFloatPoolProposal("code-119", title: "title-735")
        try item.moveTo(Staffing.FloatPoolProposalStatus.rejected)
        #expect(item.status == Staffing.FloatPoolProposalStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newFloatPoolProposal("code-119", title: "title-735")
        item.status = Staffing.FloatPoolProposalStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolProposalStatus.proposed) }
    }
}
