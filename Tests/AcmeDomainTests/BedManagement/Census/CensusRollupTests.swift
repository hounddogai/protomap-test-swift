@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusRollupTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newCensusRollup("code-243", name: "name-512")
        #expect(item.status == BedManagement.CensusRollupStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = BedManagement.newCensusRollup("code-243", name: "name-512")
        try item.moveTo(BedManagement.CensusRollupStatus.inProgress)
        #expect(item.status == BedManagement.CensusRollupStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newCensusRollup("code-243", name: "name-512")
        item.status = BedManagement.CensusRollupStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusRollupStatus.planned) }
    }
}
