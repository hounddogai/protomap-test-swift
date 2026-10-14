@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftProfileTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newShiftProfile("code-478", name: "name-687")
        #expect(item.status == Staffing.ShiftProfileStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Staffing.newShiftProfile("code-478", name: "name-687")
        try item.moveTo(Staffing.ShiftProfileStatus.suspended)
        #expect(item.status == Staffing.ShiftProfileStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newShiftProfile("code-478", name: "name-687")
        item.status = Staffing.ShiftProfileStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ShiftProfileStatus.draft) }
    }
}
