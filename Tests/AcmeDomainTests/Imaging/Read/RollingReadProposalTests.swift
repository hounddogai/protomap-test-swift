@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingReadProposalTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newRollingReadProposal("code-911", title: "title-261")
        #expect(item.status == Imaging.RollingReadProposalStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Imaging.newRollingReadProposal("code-911", title: "title-261")
        try item.moveTo(Imaging.RollingReadProposalStatus.inProgress)
        #expect(item.status == Imaging.RollingReadProposalStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newRollingReadProposal("code-911", title: "title-261")
        item.status = Imaging.RollingReadProposalStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.RollingReadProposalStatus.planned) }
    }
}
