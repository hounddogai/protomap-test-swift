@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenLedgerTests {
    @Test func startsInIdle() throws {
        let item = Labs.newSpecimenLedger("code-494", name: "name-12")
        #expect(item.status == Labs.SpecimenLedgerStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Labs.newSpecimenLedger("code-494", name: "name-12")
        try item.moveTo(Labs.SpecimenLedgerStatus.warming)
        #expect(item.status == Labs.SpecimenLedgerStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newSpecimenLedger("code-494", name: "name-12")
        item.status = Labs.SpecimenLedgerStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenLedgerStatus.idle) }
    }
}
