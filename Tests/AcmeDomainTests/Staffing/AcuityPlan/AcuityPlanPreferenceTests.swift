@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanPreferenceTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newAcuityPlanPreference("code-229", name: "name-937")
        #expect(item.status == Staffing.AcuityPlanPreferenceStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Staffing.newAcuityPlanPreference("code-229", name: "name-937")
        try item.moveTo(Staffing.AcuityPlanPreferenceStatus.reopened)
        #expect(item.status == Staffing.AcuityPlanPreferenceStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newAcuityPlanPreference("code-229", name: "name-937")
        item.status = Staffing.AcuityPlanPreferenceStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanPreferenceStatus.`open`) }
    }
}
