@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreScheduleTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newRiskScoreSchedule("code-26", name: "name-311")
        #expect(item.status == CareManagement.RiskScoreScheduleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = CareManagement.newRiskScoreSchedule("code-26", name: "name-311")
        try item.moveTo(CareManagement.RiskScoreScheduleStatus.granted)
        #expect(item.status == CareManagement.RiskScoreScheduleStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newRiskScoreSchedule("code-26", name: "name-311")
        item.status = CareManagement.RiskScoreScheduleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScoreScheduleStatus.requested) }
    }
}
