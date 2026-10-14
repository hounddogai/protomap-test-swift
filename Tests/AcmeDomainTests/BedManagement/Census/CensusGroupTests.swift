@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusGroupTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newCensusGroup("code-542", title: "title-286")
        #expect(item.status == BedManagement.CensusGroupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = BedManagement.newCensusGroup("code-542", title: "title-286")
        try item.moveTo(BedManagement.CensusGroupStatus.queued)
        #expect(item.status == BedManagement.CensusGroupStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newCensusGroup("code-542", title: "title-286")
        item.status = BedManagement.CensusGroupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusGroupStatus.new) }
    }
}
