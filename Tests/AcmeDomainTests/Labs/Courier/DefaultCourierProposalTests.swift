@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultCourierProposalTests {
    @Test func startsInIdle() throws {
        let item = Labs.newDefaultCourierProposal("code-758", name: "name-27")
        #expect(item.status == Labs.DefaultCourierProposalStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Labs.newDefaultCourierProposal("code-758", name: "name-27")
        try item.moveTo(Labs.DefaultCourierProposalStatus.ready)
        #expect(item.status == Labs.DefaultCourierProposalStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newDefaultCourierProposal("code-758", name: "name-27")
        item.status = Labs.DefaultCourierProposalStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.DefaultCourierProposalStatus.idle) }
    }
}
