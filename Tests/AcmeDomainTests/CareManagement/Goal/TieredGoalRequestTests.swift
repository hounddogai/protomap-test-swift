@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredGoalRequestTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newTieredGoalRequest("code-70", title: "title-724")
        #expect(item.status == CareManagement.TieredGoalRequestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = CareManagement.newTieredGoalRequest("code-70", title: "title-724")
        try item.moveTo(CareManagement.TieredGoalRequestStatus.published)
        #expect(item.status == CareManagement.TieredGoalRequestStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newTieredGoalRequest("code-70", title: "title-724")
        item.status = CareManagement.TieredGoalRequestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.TieredGoalRequestStatus.created) }
    }
}
