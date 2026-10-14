@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryProposalTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newInventoryProposal("code-748", label: "label-343")
        #expect(item.status == Pharmacy.InventoryProposalStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Pharmacy.newInventoryProposal("code-748", label: "label-343")
        try item.moveTo(Pharmacy.InventoryProposalStatus.validated)
        #expect(item.status == Pharmacy.InventoryProposalStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newInventoryProposal("code-748", label: "label-343")
        item.status = Pharmacy.InventoryProposalStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryProposalStatus.created) }
    }
}
