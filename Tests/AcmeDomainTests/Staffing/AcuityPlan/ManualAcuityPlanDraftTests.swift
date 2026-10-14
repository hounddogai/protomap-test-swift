@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualAcuityPlanDraftTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newManualAcuityPlanDraft("code-188", name: "name-663")
        #expect(item.status == Staffing.ManualAcuityPlanDraftStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Staffing.newManualAcuityPlanDraft("code-188", name: "name-663")
        try item.moveTo(Staffing.ManualAcuityPlanDraftStatus.expired)
        #expect(item.status == Staffing.ManualAcuityPlanDraftStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newManualAcuityPlanDraft("code-188", name: "name-663")
        item.status = Staffing.ManualAcuityPlanDraftStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ManualAcuityPlanDraftStatus.requested) }
    }
}
