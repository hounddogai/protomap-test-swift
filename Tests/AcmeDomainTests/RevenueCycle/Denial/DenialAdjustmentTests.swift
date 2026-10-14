@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialAdjustmentTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newDenialAdjustment("code-839", name: "name-149")
        #expect(item.status == RevenueCycle.DenialAdjustmentStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = RevenueCycle.newDenialAdjustment("code-839", name: "name-149")
        try item.moveTo(RevenueCycle.DenialAdjustmentStatus.queued)
        #expect(item.status == RevenueCycle.DenialAdjustmentStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newDenialAdjustment("code-839", name: "name-149")
        item.status = RevenueCycle.DenialAdjustmentStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialAdjustmentStatus.new) }
    }
}
