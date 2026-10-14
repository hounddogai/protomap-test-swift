@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallLedgerTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newRecallLedger("code-20", name: "name-519")
        #expect(item.status == Pharmacy.RecallLedgerStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newRecallLedger("code-20", name: "name-519")
        try item.moveTo(Pharmacy.RecallLedgerStatus.approved)
        #expect(item.status == Pharmacy.RecallLedgerStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newRecallLedger("code-20", name: "name-519")
        item.status = Pharmacy.RecallLedgerStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallLedgerStatus.proposed) }
    }
}
