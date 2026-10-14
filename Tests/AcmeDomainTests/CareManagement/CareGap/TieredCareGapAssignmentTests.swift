@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredCareGapAssignmentTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newTieredCareGapAssignment("code-942", name: "name-942")
        #expect(item.status == CareManagement.TieredCareGapAssignmentStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = CareManagement.newTieredCareGapAssignment("code-942", name: "name-942")
        try item.moveTo(CareManagement.TieredCareGapAssignmentStatus.inReview)
        #expect(item.status == CareManagement.TieredCareGapAssignmentStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newTieredCareGapAssignment("code-942", name: "name-942")
        item.status = CareManagement.TieredCareGapAssignmentStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.TieredCareGapAssignmentStatus.`open`) }
    }
}
