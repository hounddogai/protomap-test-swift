@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultGoalSegmentTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newDefaultGoalSegment("code-989", title: "title-699")
        #expect(item.status == CareManagement.DefaultGoalSegmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = CareManagement.newDefaultGoalSegment("code-989", title: "title-699")
        try item.moveTo(CareManagement.DefaultGoalSegmentStatus.approved)
        #expect(item.status == CareManagement.DefaultGoalSegmentStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newDefaultGoalSegment("code-989", title: "title-699")
        item.status = CareManagement.DefaultGoalSegmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.DefaultGoalSegmentStatus.proposed) }
    }
}
