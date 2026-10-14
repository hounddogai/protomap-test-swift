@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanSegmentTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newDischargePlanSegment("code-969", name: "name-859")
        #expect(item.status == BedManagement.DischargePlanSegmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = BedManagement.newDischargePlanSegment("code-969", name: "name-859")
        try item.moveTo(BedManagement.DischargePlanSegmentStatus.published)
        #expect(item.status == BedManagement.DischargePlanSegmentStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newDischargePlanSegment("code-969", name: "name-859")
        item.status = BedManagement.DischargePlanSegmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DischargePlanSegmentStatus.created) }
    }
}
