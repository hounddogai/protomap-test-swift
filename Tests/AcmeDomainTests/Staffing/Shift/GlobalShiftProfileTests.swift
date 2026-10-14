@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalShiftProfileTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newGlobalShiftProfile("code-100", name: "name-635")
        #expect(item.status == Staffing.GlobalShiftProfileStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Staffing.newGlobalShiftProfile("code-100", name: "name-635")
        try item.moveTo(Staffing.GlobalShiftProfileStatus.suspended)
        #expect(item.status == Staffing.GlobalShiftProfileStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newGlobalShiftProfile("code-100", name: "name-635")
        item.status = Staffing.GlobalShiftProfileStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.GlobalShiftProfileStatus.draft) }
    }
}
