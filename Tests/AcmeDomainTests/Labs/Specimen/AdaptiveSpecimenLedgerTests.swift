@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveSpecimenLedgerTests {
    @Test func startsInProposed() throws {
        let item = Labs.newAdaptiveSpecimenLedger("code-112", label: "label-452")
        #expect(item.status == Labs.AdaptiveSpecimenLedgerStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newAdaptiveSpecimenLedger("code-112", label: "label-452")
        try item.moveTo(Labs.AdaptiveSpecimenLedgerStatus.approved)
        #expect(item.status == Labs.AdaptiveSpecimenLedgerStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newAdaptiveSpecimenLedger("code-112", label: "label-452")
        item.status = Labs.AdaptiveSpecimenLedgerStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AdaptiveSpecimenLedgerStatus.proposed) }
    }
}
