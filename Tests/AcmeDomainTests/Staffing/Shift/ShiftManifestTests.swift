@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftManifestTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newShiftManifest("code-44", label: "label-970")
        #expect(item.status == Staffing.ShiftManifestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Staffing.newShiftManifest("code-44", label: "label-970")
        try item.moveTo(Staffing.ShiftManifestStatus.pending)
        #expect(item.status == Staffing.ShiftManifestStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newShiftManifest("code-44", label: "label-970")
        item.status = Staffing.ShiftManifestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ShiftManifestStatus.draft) }
    }
}
