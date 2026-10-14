@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierProposalTests {
    @Test func startsInOpen() throws {
        let item = Labs.newCourierProposal("code-402", name: "name-557")
        #expect(item.status == Labs.CourierProposalStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Labs.newCourierProposal("code-402", name: "name-557")
        try item.moveTo(Labs.CourierProposalStatus.reopened)
        #expect(item.status == Labs.CourierProposalStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newCourierProposal("code-402", name: "name-557")
        item.status = Labs.CourierProposalStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierProposalStatus.`open`) }
    }
}
