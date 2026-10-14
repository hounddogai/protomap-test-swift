@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultRecallProposalTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newDefaultRecallProposal("code-73", name: "name-411")
        #expect(item.status == Pharmacy.DefaultRecallProposalStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Pharmacy.newDefaultRecallProposal("code-73", name: "name-411")
        try item.moveTo(Pharmacy.DefaultRecallProposalStatus.published)
        #expect(item.status == Pharmacy.DefaultRecallProposalStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newDefaultRecallProposal("code-73", name: "name-411")
        item.status = Pharmacy.DefaultRecallProposalStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DefaultRecallProposalStatus.created) }
    }
}
