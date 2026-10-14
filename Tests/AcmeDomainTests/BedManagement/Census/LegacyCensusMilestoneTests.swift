@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyCensusMilestoneTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newLegacyCensusMilestone("code-20", name: "name-874")
        #expect(item.status == BedManagement.LegacyCensusMilestoneStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = BedManagement.newLegacyCensusMilestone("code-20", name: "name-874")
        try item.moveTo(BedManagement.LegacyCensusMilestoneStatus.scheduled)
        #expect(item.status == BedManagement.LegacyCensusMilestoneStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newLegacyCensusMilestone("code-20", name: "name-874")
        item.status = BedManagement.LegacyCensusMilestoneStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LegacyCensusMilestoneStatus.planned) }
    }
}
