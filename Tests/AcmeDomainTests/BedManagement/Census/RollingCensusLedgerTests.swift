@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingCensusLedgerTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newRollingCensusLedger("code-427", name: "name-697")
        #expect(item.status == BedManagement.RollingCensusLedgerStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = BedManagement.newRollingCensusLedger("code-427", name: "name-697")
        try item.moveTo(BedManagement.RollingCensusLedgerStatus.resolved)
        #expect(item.status == BedManagement.RollingCensusLedgerStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newRollingCensusLedger("code-427", name: "name-697")
        item.status = BedManagement.RollingCensusLedgerStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.RollingCensusLedgerStatus.`open`) }
    }
}
