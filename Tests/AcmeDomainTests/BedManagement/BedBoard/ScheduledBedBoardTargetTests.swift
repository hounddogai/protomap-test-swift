@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledBedBoardTargetTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newScheduledBedBoardTarget("code-271", label: "label-970")
        #expect(item.status == BedManagement.ScheduledBedBoardTargetStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = BedManagement.newScheduledBedBoardTarget("code-271", label: "label-970")
        try item.moveTo(BedManagement.ScheduledBedBoardTargetStatus.published)
        #expect(item.status == BedManagement.ScheduledBedBoardTargetStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newScheduledBedBoardTarget("code-271", label: "label-970")
        item.status = BedManagement.ScheduledBedBoardTargetStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ScheduledBedBoardTargetStatus.created) }
    }
}
