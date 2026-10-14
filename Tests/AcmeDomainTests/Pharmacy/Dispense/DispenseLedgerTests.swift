@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseLedgerTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newDispenseLedger("code-5", title: "title-12")
        #expect(item.status == Pharmacy.DispenseLedgerStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Pharmacy.newDispenseLedger("code-5", title: "title-12")
        try item.moveTo(Pharmacy.DispenseLedgerStatus.validated)
        #expect(item.status == Pharmacy.DispenseLedgerStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newDispenseLedger("code-5", title: "title-12")
        item.status = Pharmacy.DispenseLedgerStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseLedgerStatus.created) }
    }
}
