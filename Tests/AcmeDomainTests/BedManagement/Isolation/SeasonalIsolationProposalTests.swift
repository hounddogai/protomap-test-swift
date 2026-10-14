@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementSeasonalIsolationProposalTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newSeasonalIsolationProposal("code-706", title: "title-706")
        #expect(item.status == BedManagement.SeasonalIsolationProposalStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = BedManagement.newSeasonalIsolationProposal("code-706", title: "title-706")
        try item.moveTo(BedManagement.SeasonalIsolationProposalStatus.running)
        #expect(item.status == BedManagement.SeasonalIsolationProposalStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newSeasonalIsolationProposal("code-706", title: "title-706")
        item.status = BedManagement.SeasonalIsolationProposalStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.SeasonalIsolationProposalStatus.new) }
    }
}
