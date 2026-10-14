@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictInventoryLedgerTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newStrictInventoryLedger("code-280", title: "title-512")
        #expect(item.status == Pharmacy.StrictInventoryLedgerStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Pharmacy.newStrictInventoryLedger("code-280", title: "title-512")
        try item.moveTo(Pharmacy.StrictInventoryLedgerStatus.inReview)
        #expect(item.status == Pharmacy.StrictInventoryLedgerStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newStrictInventoryLedger("code-280", title: "title-512")
        item.status = Pharmacy.StrictInventoryLedgerStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.StrictInventoryLedgerStatus.`open`) }
    }
}
