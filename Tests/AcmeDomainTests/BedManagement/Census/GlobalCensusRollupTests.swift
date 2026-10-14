@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalCensusRollupTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newGlobalCensusRollup("code-421", name: "name-365")
        #expect(item.status == BedManagement.GlobalCensusRollupStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = BedManagement.newGlobalCensusRollup("code-421", name: "name-365")
        try item.moveTo(BedManagement.GlobalCensusRollupStatus.active)
        #expect(item.status == BedManagement.GlobalCensusRollupStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newGlobalCensusRollup("code-421", name: "name-365")
        item.status = BedManagement.GlobalCensusRollupStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.GlobalCensusRollupStatus.draft) }
    }
}
