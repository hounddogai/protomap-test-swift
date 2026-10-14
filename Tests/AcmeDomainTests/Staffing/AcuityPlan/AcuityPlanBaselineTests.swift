@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanBaselineTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newAcuityPlanBaseline("code-255", title: "title-208")
        #expect(item.status == Staffing.AcuityPlanBaselineStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Staffing.newAcuityPlanBaseline("code-255", title: "title-208")
        try item.moveTo(Staffing.AcuityPlanBaselineStatus.validated)
        #expect(item.status == Staffing.AcuityPlanBaselineStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newAcuityPlanBaseline("code-255", title: "title-208")
        item.status = Staffing.AcuityPlanBaselineStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanBaselineStatus.created) }
    }
}
