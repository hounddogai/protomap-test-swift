@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingRecallProposalTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newPendingRecallProposal("code-62", title: "title-131")
        #expect(item.status == Pharmacy.PendingRecallProposalStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Pharmacy.newPendingRecallProposal("code-62", title: "title-131")
        try item.moveTo(Pharmacy.PendingRecallProposalStatus.ready)
        #expect(item.status == Pharmacy.PendingRecallProposalStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newPendingRecallProposal("code-62", title: "title-131")
        item.status = Pharmacy.PendingRecallProposalStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PendingRecallProposalStatus.idle) }
    }
}
