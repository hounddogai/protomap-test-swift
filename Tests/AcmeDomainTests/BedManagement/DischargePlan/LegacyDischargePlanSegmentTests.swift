@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyDischargePlanSegmentTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newLegacyDischargePlanSegment("code-844", title: "title-94")
        #expect(item.status == BedManagement.LegacyDischargePlanSegmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = BedManagement.newLegacyDischargePlanSegment("code-844", title: "title-94")
        try item.moveTo(BedManagement.LegacyDischargePlanSegmentStatus.rejected)
        #expect(item.status == BedManagement.LegacyDischargePlanSegmentStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newLegacyDischargePlanSegment("code-844", title: "title-94")
        item.status = BedManagement.LegacyDischargePlanSegmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LegacyDischargePlanSegmentStatus.proposed) }
    }
}
