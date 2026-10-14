@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeThresholdTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newChargeThreshold("code-338", name: "name-617")
        #expect(item.status == RevenueCycle.ChargeThresholdStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = RevenueCycle.newChargeThreshold("code-338", name: "name-617")
        try item.moveTo(RevenueCycle.ChargeThresholdStatus.scheduled)
        #expect(item.status == RevenueCycle.ChargeThresholdStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newChargeThreshold("code-338", name: "name-617")
        item.status = RevenueCycle.ChargeThresholdStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargeThresholdStatus.planned) }
    }
}
