@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanScoreTests {
    @Test func startsInNew() throws {
        let item = Staffing.newAcuityPlanScore("code-989", name: "name-136")
        #expect(item.status == Staffing.AcuityPlanScoreStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Staffing.newAcuityPlanScore("code-989", name: "name-136")
        try item.moveTo(Staffing.AcuityPlanScoreStatus.failed)
        #expect(item.status == Staffing.AcuityPlanScoreStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newAcuityPlanScore("code-989", name: "name-136")
        item.status = Staffing.AcuityPlanScoreStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanScoreStatus.new) }
    }
}
