@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalRecallProposalTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newRegionalRecallProposal("code-558", name: "name-870")
        #expect(item.status == Pharmacy.RegionalRecallProposalStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Pharmacy.newRegionalRecallProposal("code-558", name: "name-870")
        try item.moveTo(Pharmacy.RegionalRecallProposalStatus.reopened)
        #expect(item.status == Pharmacy.RegionalRecallProposalStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newRegionalRecallProposal("code-558", name: "name-870")
        item.status = Pharmacy.RegionalRecallProposalStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RegionalRecallProposalStatus.`open`) }
    }
}
