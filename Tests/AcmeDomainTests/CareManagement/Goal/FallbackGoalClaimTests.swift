@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackGoalClaimTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newFallbackGoalClaim("code-618", title: "title-78")
        #expect(item.status == CareManagement.FallbackGoalClaimStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = CareManagement.newFallbackGoalClaim("code-618", title: "title-78")
        try item.moveTo(CareManagement.FallbackGoalClaimStatus.scheduled)
        #expect(item.status == CareManagement.FallbackGoalClaimStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newFallbackGoalClaim("code-618", title: "title-78")
        item.status = CareManagement.FallbackGoalClaimStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.FallbackGoalClaimStatus.planned) }
    }
}
