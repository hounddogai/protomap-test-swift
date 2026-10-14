@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanProfileTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newAcuityPlanProfile("code-614", label: "label-148")
        #expect(item.status == Staffing.AcuityPlanProfileStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Staffing.newAcuityPlanProfile("code-614", label: "label-148")
        try item.moveTo(Staffing.AcuityPlanProfileStatus.closed)
        #expect(item.status == Staffing.AcuityPlanProfileStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newAcuityPlanProfile("code-614", label: "label-148")
        item.status = Staffing.AcuityPlanProfileStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanProfileStatus.draft) }
    }
}
