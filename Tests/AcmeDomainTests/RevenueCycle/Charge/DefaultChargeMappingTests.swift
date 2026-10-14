@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultChargeMappingTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newDefaultChargeMapping("code-504", label: "label-791")
        #expect(item.status == RevenueCycle.DefaultChargeMappingStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = RevenueCycle.newDefaultChargeMapping("code-504", label: "label-791")
        try item.moveTo(RevenueCycle.DefaultChargeMappingStatus.scheduled)
        #expect(item.status == RevenueCycle.DefaultChargeMappingStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newDefaultChargeMapping("code-504", label: "label-791")
        item.status = RevenueCycle.DefaultChargeMappingStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DefaultChargeMappingStatus.planned) }
    }
}
