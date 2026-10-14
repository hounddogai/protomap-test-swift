@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredClaimThresholdTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newTieredClaimThreshold("code-840", label: "label-705")
        #expect(item.status == RevenueCycle.TieredClaimThresholdStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = RevenueCycle.newTieredClaimThreshold("code-840", label: "label-705")
        try item.moveTo(RevenueCycle.TieredClaimThresholdStatus.warming)
        #expect(item.status == RevenueCycle.TieredClaimThresholdStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newTieredClaimThreshold("code-840", label: "label-705")
        item.status = RevenueCycle.TieredClaimThresholdStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.TieredClaimThresholdStatus.idle) }
    }
}
