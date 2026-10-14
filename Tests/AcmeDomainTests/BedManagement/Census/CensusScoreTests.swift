@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusScoreTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newCensusScore("code-979", label: "label-774")
        #expect(item.status == BedManagement.CensusScoreStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = BedManagement.newCensusScore("code-979", label: "label-774")
        try item.moveTo(BedManagement.CensusScoreStatus.done)
        #expect(item.status == BedManagement.CensusScoreStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newCensusScore("code-979", label: "label-774")
        item.status = BedManagement.CensusScoreStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusScoreStatus.new) }
    }
}
