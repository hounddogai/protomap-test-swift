@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredChargeTierTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newTieredChargeTier("code-210", name: "name-262")
        #expect(item.status == RevenueCycle.TieredChargeTierStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = RevenueCycle.newTieredChargeTier("code-210", name: "name-262")
        try item.moveTo(RevenueCycle.TieredChargeTierStatus.inProgress)
        #expect(item.status == RevenueCycle.TieredChargeTierStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newTieredChargeTier("code-210", name: "name-262")
        item.status = RevenueCycle.TieredChargeTierStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.TieredChargeTierStatus.planned) }
    }
}
