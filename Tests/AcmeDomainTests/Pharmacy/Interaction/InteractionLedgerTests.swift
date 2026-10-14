@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionLedgerTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newInteractionLedger("code-346", name: "name-326")
        #expect(item.status == Pharmacy.InteractionLedgerStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Pharmacy.newInteractionLedger("code-346", name: "name-326")
        try item.moveTo(Pharmacy.InteractionLedgerStatus.resolved)
        #expect(item.status == Pharmacy.InteractionLedgerStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newInteractionLedger("code-346", name: "name-326")
        item.status = Pharmacy.InteractionLedgerStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InteractionLedgerStatus.`open`) }
    }
}
