@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusBaselineTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newCensusBaseline("code-216", label: "label-490")
        #expect(item.status == BedManagement.CensusBaselineStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = BedManagement.newCensusBaseline("code-216", label: "label-490")
        try item.moveTo(BedManagement.CensusBaselineStatus.queued)
        #expect(item.status == BedManagement.CensusBaselineStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newCensusBaseline("code-216", label: "label-490")
        item.status = BedManagement.CensusBaselineStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusBaselineStatus.new) }
    }
}
