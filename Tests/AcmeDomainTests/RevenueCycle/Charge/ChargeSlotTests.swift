@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeSlotTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newChargeSlot("code-510", label: "label-524")
        #expect(item.status == RevenueCycle.ChargeSlotStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = RevenueCycle.newChargeSlot("code-510", label: "label-524")
        try item.moveTo(RevenueCycle.ChargeSlotStatus.validated)
        #expect(item.status == RevenueCycle.ChargeSlotStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newChargeSlot("code-510", label: "label-524")
        item.status = RevenueCycle.ChargeSlotStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargeSlotStatus.created) }
    }
}
