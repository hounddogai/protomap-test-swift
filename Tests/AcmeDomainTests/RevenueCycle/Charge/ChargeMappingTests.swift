@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeMappingTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newChargeMapping("code-790", label: "label-149")
        #expect(item.status == RevenueCycle.ChargeMappingStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = RevenueCycle.newChargeMapping("code-790", label: "label-149")
        try item.moveTo(RevenueCycle.ChargeMappingStatus.validated)
        #expect(item.status == RevenueCycle.ChargeMappingStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newChargeMapping("code-790", label: "label-149")
        item.status = RevenueCycle.ChargeMappingStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargeMappingStatus.created) }
    }
}
