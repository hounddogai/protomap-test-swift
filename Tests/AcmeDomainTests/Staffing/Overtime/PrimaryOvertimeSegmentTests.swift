@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryOvertimeSegmentTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newPrimaryOvertimeSegment("code-762", name: "name-115")
        #expect(item.status == Staffing.PrimaryOvertimeSegmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Staffing.newPrimaryOvertimeSegment("code-762", name: "name-115")
        try item.moveTo(Staffing.PrimaryOvertimeSegmentStatus.pending)
        #expect(item.status == Staffing.PrimaryOvertimeSegmentStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newPrimaryOvertimeSegment("code-762", name: "name-115")
        item.status = Staffing.PrimaryOvertimeSegmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PrimaryOvertimeSegmentStatus.draft) }
    }
}
