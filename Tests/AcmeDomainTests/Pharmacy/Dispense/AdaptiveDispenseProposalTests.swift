@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveDispenseProposalTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newAdaptiveDispenseProposal("code-125", title: "title-66")
        #expect(item.status == Pharmacy.AdaptiveDispenseProposalStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Pharmacy.newAdaptiveDispenseProposal("code-125", title: "title-66")
        try item.moveTo(Pharmacy.AdaptiveDispenseProposalStatus.running)
        #expect(item.status == Pharmacy.AdaptiveDispenseProposalStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newAdaptiveDispenseProposal("code-125", title: "title-66")
        item.status = Pharmacy.AdaptiveDispenseProposalStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.AdaptiveDispenseProposalStatus.new) }
    }
}
