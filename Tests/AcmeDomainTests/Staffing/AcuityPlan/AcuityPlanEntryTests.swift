@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanEntryTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newAcuityPlanEntry("code-818", name: "name-553")
        #expect(item.status == Staffing.AcuityPlanEntryStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Staffing.newAcuityPlanEntry("code-818", name: "name-553")
        try item.moveTo(Staffing.AcuityPlanEntryStatus.pending)
        #expect(item.status == Staffing.AcuityPlanEntryStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newAcuityPlanEntry("code-818", name: "name-553")
        item.status = Staffing.AcuityPlanEntryStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanEntryStatus.draft) }
    }
}
