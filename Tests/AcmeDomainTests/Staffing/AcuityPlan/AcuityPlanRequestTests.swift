@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanRequestTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newAcuityPlanRequest("code-656", name: "name-175")
        #expect(item.status == Staffing.AcuityPlanRequestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Staffing.newAcuityPlanRequest("code-656", name: "name-175")
        try item.moveTo(Staffing.AcuityPlanRequestStatus.pending)
        #expect(item.status == Staffing.AcuityPlanRequestStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newAcuityPlanRequest("code-656", name: "name-175")
        item.status = Staffing.AcuityPlanRequestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanRequestStatus.draft) }
    }
}
