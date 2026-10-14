@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanTierTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newAcuityPlanTier("code-371", name: "name-66")
        #expect(item.status == Staffing.AcuityPlanTierStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Staffing.newAcuityPlanTier("code-371", name: "name-66")
        try item.moveTo(Staffing.AcuityPlanTierStatus.reopened)
        #expect(item.status == Staffing.AcuityPlanTierStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newAcuityPlanTier("code-371", name: "name-66")
        item.status = Staffing.AcuityPlanTierStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanTierStatus.`open`) }
    }
}
