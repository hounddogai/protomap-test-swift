@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargePolicyTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newChargePolicy("code-691", label: "label-537")
        #expect(item.status == RevenueCycle.ChargePolicyStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = RevenueCycle.newChargePolicy("code-691", label: "label-537")
        try item.moveTo(RevenueCycle.ChargePolicyStatus.scheduled)
        #expect(item.status == RevenueCycle.ChargePolicyStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newChargePolicy("code-691", label: "label-537")
        item.status = RevenueCycle.ChargePolicyStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargePolicyStatus.planned) }
    }
}
