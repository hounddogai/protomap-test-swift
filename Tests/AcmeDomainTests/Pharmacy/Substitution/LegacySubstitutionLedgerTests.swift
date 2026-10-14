@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacySubstitutionLedgerTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newLegacySubstitutionLedger("code-529", title: "title-5")
        #expect(item.status == Pharmacy.LegacySubstitutionLedgerStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Pharmacy.newLegacySubstitutionLedger("code-529", title: "title-5")
        try item.moveTo(Pharmacy.LegacySubstitutionLedgerStatus.warming)
        #expect(item.status == Pharmacy.LegacySubstitutionLedgerStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newLegacySubstitutionLedger("code-529", title: "title-5")
        item.status = Pharmacy.LegacySubstitutionLedgerStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LegacySubstitutionLedgerStatus.idle) }
    }
}
