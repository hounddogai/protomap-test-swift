@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientShiftThresholdTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newLenientShiftThreshold("code-468", name: "name-972")
        #expect(item.status == Staffing.LenientShiftThresholdStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Staffing.newLenientShiftThreshold("code-468", name: "name-972")
        try item.moveTo(Staffing.LenientShiftThresholdStatus.approved)
        #expect(item.status == Staffing.LenientShiftThresholdStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newLenientShiftThreshold("code-468", name: "name-972")
        item.status = Staffing.LenientShiftThresholdStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.LenientShiftThresholdStatus.proposed) }
    }
}
