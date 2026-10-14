@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedAcuityPlanDraftTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newCappedAcuityPlanDraft("code-710", name: "name-805")
        #expect(item.status == Staffing.CappedAcuityPlanDraftStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Staffing.newCappedAcuityPlanDraft("code-710", name: "name-805")
        try item.moveTo(Staffing.CappedAcuityPlanDraftStatus.approved)
        #expect(item.status == Staffing.CappedAcuityPlanDraftStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newCappedAcuityPlanDraft("code-710", name: "name-805")
        item.status = Staffing.CappedAcuityPlanDraftStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CappedAcuityPlanDraftStatus.proposed) }
    }
}
