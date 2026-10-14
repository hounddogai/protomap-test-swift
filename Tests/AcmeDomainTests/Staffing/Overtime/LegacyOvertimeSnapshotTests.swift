@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacyOvertimeSnapshotTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newLegacyOvertimeSnapshot("code-462", title: "title-721")
        #expect(item.status == Staffing.LegacyOvertimeSnapshotStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Staffing.newLegacyOvertimeSnapshot("code-462", title: "title-721")
        try item.moveTo(Staffing.LegacyOvertimeSnapshotStatus.inReview)
        #expect(item.status == Staffing.LegacyOvertimeSnapshotStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newLegacyOvertimeSnapshot("code-462", title: "title-721")
        item.status = Staffing.LegacyOvertimeSnapshotStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.LegacyOvertimeSnapshotStatus.`open`) }
    }
}
