@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeOverrideTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newChargeOverride("code-64", name: "name-809")
        #expect(item.status == RevenueCycle.ChargeOverrideStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = RevenueCycle.newChargeOverride("code-64", name: "name-809")
        try item.moveTo(RevenueCycle.ChargeOverrideStatus.scheduled)
        #expect(item.status == RevenueCycle.ChargeOverrideStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newChargeOverride("code-64", name: "name-809")
        item.status = RevenueCycle.ChargeOverrideStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargeOverrideStatus.planned) }
    }
}
