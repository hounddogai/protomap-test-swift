@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultBedBoardBaselineTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newDefaultBedBoardBaseline("code-963", name: "name-487")
        #expect(item.status == BedManagement.DefaultBedBoardBaselineStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = BedManagement.newDefaultBedBoardBaseline("code-963", name: "name-487")
        try item.moveTo(BedManagement.DefaultBedBoardBaselineStatus.scheduled)
        #expect(item.status == BedManagement.DefaultBedBoardBaselineStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newDefaultBedBoardBaseline("code-963", name: "name-487")
        item.status = BedManagement.DefaultBedBoardBaselineStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DefaultBedBoardBaselineStatus.planned) }
    }
}
