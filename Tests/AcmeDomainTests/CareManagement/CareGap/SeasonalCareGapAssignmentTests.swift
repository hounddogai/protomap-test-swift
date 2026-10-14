@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalCareGapAssignmentTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newSeasonalCareGapAssignment("code-86", name: "name-463")
        #expect(item.status == CareManagement.SeasonalCareGapAssignmentStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = CareManagement.newSeasonalCareGapAssignment("code-86", name: "name-463")
        try item.moveTo(CareManagement.SeasonalCareGapAssignmentStatus.reopened)
        #expect(item.status == CareManagement.SeasonalCareGapAssignmentStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newSeasonalCareGapAssignment("code-86", name: "name-463")
        item.status = CareManagement.SeasonalCareGapAssignmentStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.SeasonalCareGapAssignmentStatus.`open`) }
    }
}
