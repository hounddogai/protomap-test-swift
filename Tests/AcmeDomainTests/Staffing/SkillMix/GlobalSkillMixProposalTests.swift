@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalSkillMixProposalTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newGlobalSkillMixProposal("code-108", title: "title-194")
        #expect(item.status == Staffing.GlobalSkillMixProposalStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Staffing.newGlobalSkillMixProposal("code-108", title: "title-194")
        try item.moveTo(Staffing.GlobalSkillMixProposalStatus.ready)
        #expect(item.status == Staffing.GlobalSkillMixProposalStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newGlobalSkillMixProposal("code-108", title: "title-194")
        item.status = Staffing.GlobalSkillMixProposalStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.GlobalSkillMixProposalStatus.idle) }
    }
}
