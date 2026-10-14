@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictInventoryProposalTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newStrictInventoryProposal("code-180", label: "label-561")
        #expect(item.status == Pharmacy.StrictInventoryProposalStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Pharmacy.newStrictInventoryProposal("code-180", label: "label-561")
        try item.moveTo(Pharmacy.StrictInventoryProposalStatus.published)
        #expect(item.status == Pharmacy.StrictInventoryProposalStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newStrictInventoryProposal("code-180", label: "label-561")
        item.status = Pharmacy.StrictInventoryProposalStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.StrictInventoryProposalStatus.created) }
    }
}
