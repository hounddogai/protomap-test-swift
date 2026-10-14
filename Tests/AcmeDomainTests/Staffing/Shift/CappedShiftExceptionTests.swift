@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedShiftExceptionTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newCappedShiftException("code-335", name: "name-74")
        #expect(item.status == Staffing.CappedShiftExceptionStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Staffing.newCappedShiftException("code-335", name: "name-74")
        try item.moveTo(Staffing.CappedShiftExceptionStatus.approved)
        #expect(item.status == Staffing.CappedShiftExceptionStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newCappedShiftException("code-335", name: "name-74")
        item.status = Staffing.CappedShiftExceptionStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CappedShiftExceptionStatus.proposed) }
    }
}
