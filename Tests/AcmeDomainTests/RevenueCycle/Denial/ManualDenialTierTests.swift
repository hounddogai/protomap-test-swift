@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualDenialTierTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newManualDenialTier("code-293", label: "label-759")
        #expect(item.status == RevenueCycle.ManualDenialTierStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = RevenueCycle.newManualDenialTier("code-293", label: "label-759")
        try item.moveTo(RevenueCycle.ManualDenialTierStatus.running)
        #expect(item.status == RevenueCycle.ManualDenialTierStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newManualDenialTier("code-293", label: "label-759")
        item.status = RevenueCycle.ManualDenialTierStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ManualDenialTierStatus.new) }
    }
}
