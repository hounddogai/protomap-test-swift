@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackGoalRollupTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newFallbackGoalRollup("code-892", name: "name-576")
        #expect(item.status == CareManagement.FallbackGoalRollupStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = CareManagement.newFallbackGoalRollup("code-892", name: "name-576")
        try item.moveTo(CareManagement.FallbackGoalRollupStatus.ready)
        #expect(item.status == CareManagement.FallbackGoalRollupStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newFallbackGoalRollup("code-892", name: "name-576")
        item.status = CareManagement.FallbackGoalRollupStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.FallbackGoalRollupStatus.idle) }
    }
}
