@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftDraftTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newShiftDraft("code-897", name: "name-261")
        #expect(item.status == Staffing.ShiftDraftStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Staffing.newShiftDraft("code-897", name: "name-261")
        try item.moveTo(Staffing.ShiftDraftStatus.active)
        #expect(item.status == Staffing.ShiftDraftStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newShiftDraft("code-897", name: "name-261")
        item.status = Staffing.ShiftDraftStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ShiftDraftStatus.draft) }
    }
}
