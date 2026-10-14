@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryShiftWindowTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newPrimaryShiftWindow("code-107", label: "label-202")
        #expect(item.status == Staffing.PrimaryShiftWindowStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Staffing.newPrimaryShiftWindow("code-107", label: "label-202")
        try item.moveTo(Staffing.PrimaryShiftWindowStatus.validated)
        #expect(item.status == Staffing.PrimaryShiftWindowStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newPrimaryShiftWindow("code-107", label: "label-202")
        item.status = Staffing.PrimaryShiftWindowStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PrimaryShiftWindowStatus.created) }
    }
}
