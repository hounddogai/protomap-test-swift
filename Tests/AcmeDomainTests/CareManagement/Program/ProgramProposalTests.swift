@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramProposalTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newProgramProposal("code-717", label: "label-626")
        #expect(item.status == CareManagement.ProgramProposalStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = CareManagement.newProgramProposal("code-717", label: "label-626")
        try item.moveTo(CareManagement.ProgramProposalStatus.warming)
        #expect(item.status == CareManagement.ProgramProposalStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newProgramProposal("code-717", label: "label-626")
        item.status = CareManagement.ProgramProposalStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ProgramProposalStatus.idle) }
    }
}
