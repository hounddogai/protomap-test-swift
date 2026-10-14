@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedOvertimeMappingTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newCappedOvertimeMapping("code-73", name: "name-234")
        #expect(item.status == Staffing.CappedOvertimeMappingStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Staffing.newCappedOvertimeMapping("code-73", name: "name-234")
        try item.moveTo(Staffing.CappedOvertimeMappingStatus.pending)
        #expect(item.status == Staffing.CappedOvertimeMappingStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newCappedOvertimeMapping("code-73", name: "name-234")
        item.status = Staffing.CappedOvertimeMappingStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CappedOvertimeMappingStatus.draft) }
    }
}
