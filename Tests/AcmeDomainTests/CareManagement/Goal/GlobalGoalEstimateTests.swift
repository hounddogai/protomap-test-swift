@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalGoalEstimateTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newGlobalGoalEstimate("code-107", name: "name-412")
        #expect(item.status == CareManagement.GlobalGoalEstimateStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = CareManagement.newGlobalGoalEstimate("code-107", name: "name-412")
        try item.moveTo(CareManagement.GlobalGoalEstimateStatus.running)
        #expect(item.status == CareManagement.GlobalGoalEstimateStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newGlobalGoalEstimate("code-107", name: "name-412")
        item.status = CareManagement.GlobalGoalEstimateStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GlobalGoalEstimateStatus.new) }
    }
}
