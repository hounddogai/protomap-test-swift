@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultShiftProfileTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newDefaultShiftProfile("code-544", label: "label-886")
        #expect(item.status == Staffing.DefaultShiftProfileStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Staffing.newDefaultShiftProfile("code-544", label: "label-886")
        try item.moveTo(Staffing.DefaultShiftProfileStatus.rejected)
        #expect(item.status == Staffing.DefaultShiftProfileStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newDefaultShiftProfile("code-544", label: "label-886")
        item.status = Staffing.DefaultShiftProfileStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.DefaultShiftProfileStatus.proposed) }
    }
}
