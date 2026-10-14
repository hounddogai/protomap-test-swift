@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultRiskScoreScheduleTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newDefaultRiskScoreSchedule("code-555", name: "name-379")
        #expect(item.status == CareManagement.DefaultRiskScoreScheduleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = CareManagement.newDefaultRiskScoreSchedule("code-555", name: "name-379")
        try item.moveTo(CareManagement.DefaultRiskScoreScheduleStatus.validated)
        #expect(item.status == CareManagement.DefaultRiskScoreScheduleStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newDefaultRiskScoreSchedule("code-555", name: "name-379")
        item.status = CareManagement.DefaultRiskScoreScheduleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.DefaultRiskScoreScheduleStatus.created) }
    }
}
