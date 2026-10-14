@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryShiftPreferenceTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newPrimaryShiftPreference("code-104", title: "title-460")
        #expect(item.status == Staffing.PrimaryShiftPreferenceStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Staffing.newPrimaryShiftPreference("code-104", title: "title-460")
        try item.moveTo(Staffing.PrimaryShiftPreferenceStatus.approved)
        #expect(item.status == Staffing.PrimaryShiftPreferenceStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newPrimaryShiftPreference("code-104", title: "title-460")
        item.status = Staffing.PrimaryShiftPreferenceStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PrimaryShiftPreferenceStatus.proposed) }
    }
}
