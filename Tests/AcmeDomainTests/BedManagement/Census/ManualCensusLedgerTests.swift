@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualCensusLedgerTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newManualCensusLedger("code-159", name: "name-252")
        #expect(item.status == BedManagement.ManualCensusLedgerStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = BedManagement.newManualCensusLedger("code-159", name: "name-252")
        try item.moveTo(BedManagement.ManualCensusLedgerStatus.resolved)
        #expect(item.status == BedManagement.ManualCensusLedgerStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newManualCensusLedger("code-159", name: "name-252")
        item.status = BedManagement.ManualCensusLedgerStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ManualCensusLedgerStatus.`open`) }
    }
}
