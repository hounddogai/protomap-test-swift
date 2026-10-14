@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseProposalTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newDispenseProposal("code-360", name: "name-150")
        #expect(item.status == Pharmacy.DispenseProposalStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Pharmacy.newDispenseProposal("code-360", name: "name-150")
        try item.moveTo(Pharmacy.DispenseProposalStatus.archived)
        #expect(item.status == Pharmacy.DispenseProposalStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newDispenseProposal("code-360", name: "name-150")
        item.status = Pharmacy.DispenseProposalStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseProposalStatus.`open`) }
    }
}
