@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftAdjustmentTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newShiftAdjustment("code-40", label: "label-919")
        #expect(item.status == Staffing.ShiftAdjustmentStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Staffing.newShiftAdjustment("code-40", label: "label-919")
        try item.moveTo(Staffing.ShiftAdjustmentStatus.inReview)
        #expect(item.status == Staffing.ShiftAdjustmentStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newShiftAdjustment("code-40", label: "label-919")
        item.status = Staffing.ShiftAdjustmentStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ShiftAdjustmentStatus.`open`) }
    }
}
