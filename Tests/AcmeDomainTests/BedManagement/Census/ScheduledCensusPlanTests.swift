@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCensusPlanTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newScheduledCensusPlan("code-337", title: "title-289")
        #expect(item.status == BedManagement.ScheduledCensusPlanStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = BedManagement.newScheduledCensusPlan("code-337", title: "title-289")
        try item.moveTo(BedManagement.ScheduledCensusPlanStatus.active)
        #expect(item.status == BedManagement.ScheduledCensusPlanStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newScheduledCensusPlan("code-337", title: "title-289")
        item.status = BedManagement.ScheduledCensusPlanStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ScheduledCensusPlanStatus.draft) }
    }
}
