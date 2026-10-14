@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictShiftEntryTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newStrictShiftEntry("code-773", name: "name-232")
        #expect(item.status == Staffing.StrictShiftEntryStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Staffing.newStrictShiftEntry("code-773", name: "name-232")
        try item.moveTo(Staffing.StrictShiftEntryStatus.pending)
        #expect(item.status == Staffing.StrictShiftEntryStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newStrictShiftEntry("code-773", name: "name-232")
        item.status = Staffing.StrictShiftEntryStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.StrictShiftEntryStatus.draft) }
    }
}
