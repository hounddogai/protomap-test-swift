@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftWindowTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newShiftWindow("code-655", name: "name-774")
        #expect(item.status == Staffing.ShiftWindowStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Staffing.newShiftWindow("code-655", name: "name-774")
        try item.moveTo(Staffing.ShiftWindowStatus.rejected)
        #expect(item.status == Staffing.ShiftWindowStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newShiftWindow("code-655", name: "name-774")
        item.status = Staffing.ShiftWindowStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ShiftWindowStatus.proposed) }
    }
}
