@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredChargeBatchTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newTieredChargeBatch("code-49", label: "label-899")
        #expect(item.status == RevenueCycle.TieredChargeBatchStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = RevenueCycle.newTieredChargeBatch("code-49", label: "label-899")
        try item.moveTo(RevenueCycle.TieredChargeBatchStatus.revoked)
        #expect(item.status == RevenueCycle.TieredChargeBatchStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newTieredChargeBatch("code-49", label: "label-899")
        item.status = RevenueCycle.TieredChargeBatchStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.TieredChargeBatchStatus.requested) }
    }
}
