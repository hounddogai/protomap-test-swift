@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredRemittanceCheckpointTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newTieredRemittanceCheckpoint("code-964", name: "name-292")
        #expect(item.status == RevenueCycle.TieredRemittanceCheckpointStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = RevenueCycle.newTieredRemittanceCheckpoint("code-964", name: "name-292")
        try item.moveTo(RevenueCycle.TieredRemittanceCheckpointStatus.completed)
        #expect(item.status == RevenueCycle.TieredRemittanceCheckpointStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newTieredRemittanceCheckpoint("code-964", name: "name-292")
        item.status = RevenueCycle.TieredRemittanceCheckpointStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.TieredRemittanceCheckpointStatus.planned) }
    }
}
