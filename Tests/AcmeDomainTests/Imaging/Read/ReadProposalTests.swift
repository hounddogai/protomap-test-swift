@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadProposalTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newReadProposal("code-407", name: "name-145")
        #expect(item.status == Imaging.ReadProposalStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Imaging.newReadProposal("code-407", name: "name-145")
        try item.moveTo(Imaging.ReadProposalStatus.reopened)
        #expect(item.status == Imaging.ReadProposalStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newReadProposal("code-407", name: "name-145")
        item.status = Imaging.ReadProposalStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ReadProposalStatus.`open`) }
    }
}
