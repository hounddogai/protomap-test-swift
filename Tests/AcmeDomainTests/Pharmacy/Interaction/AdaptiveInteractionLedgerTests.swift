@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveInteractionLedgerTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newAdaptiveInteractionLedger("code-270", name: "name-71")
        #expect(item.status == Pharmacy.AdaptiveInteractionLedgerStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Pharmacy.newAdaptiveInteractionLedger("code-270", name: "name-71")
        try item.moveTo(Pharmacy.AdaptiveInteractionLedgerStatus.reopened)
        #expect(item.status == Pharmacy.AdaptiveInteractionLedgerStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newAdaptiveInteractionLedger("code-270", name: "name-71")
        item.status = Pharmacy.AdaptiveInteractionLedgerStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.AdaptiveInteractionLedgerStatus.`open`) }
    }
}
