@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanCheckpointTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newDischargePlanCheckpoint("code-719", title: "title-667")
        #expect(item.status == BedManagement.DischargePlanCheckpointStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = BedManagement.newDischargePlanCheckpoint("code-719", title: "title-667")
        try item.moveTo(BedManagement.DischargePlanCheckpointStatus.approved)
        #expect(item.status == BedManagement.DischargePlanCheckpointStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newDischargePlanCheckpoint("code-719", title: "title-667")
        item.status = BedManagement.DischargePlanCheckpointStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DischargePlanCheckpointStatus.proposed) }
    }
}
