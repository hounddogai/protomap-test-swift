@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryAcuityPlanScoreTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newPrimaryAcuityPlanScore("code-998", title: "title-344")
        #expect(item.status == Staffing.PrimaryAcuityPlanScoreStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Staffing.newPrimaryAcuityPlanScore("code-998", title: "title-344")
        try item.moveTo(Staffing.PrimaryAcuityPlanScoreStatus.pending)
        #expect(item.status == Staffing.PrimaryAcuityPlanScoreStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newPrimaryAcuityPlanScore("code-998", title: "title-344")
        item.status = Staffing.PrimaryAcuityPlanScoreStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PrimaryAcuityPlanScoreStatus.draft) }
    }
}
