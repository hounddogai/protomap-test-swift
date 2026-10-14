@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftThresholdTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newShiftThreshold("code-288", name: "name-108")
        #expect(item.status == Staffing.ShiftThresholdStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Staffing.newShiftThreshold("code-288", name: "name-108")
        try item.moveTo(Staffing.ShiftThresholdStatus.active)
        #expect(item.status == Staffing.ShiftThresholdStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newShiftThreshold("code-288", name: "name-108")
        item.status = Staffing.ShiftThresholdStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ShiftThresholdStatus.draft) }
    }
}
