@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackChargeSlotTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newFallbackChargeSlot("code-428", label: "label-18")
        #expect(item.status == RevenueCycle.FallbackChargeSlotStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = RevenueCycle.newFallbackChargeSlot("code-428", label: "label-18")
        try item.moveTo(RevenueCycle.FallbackChargeSlotStatus.revoked)
        #expect(item.status == RevenueCycle.FallbackChargeSlotStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newFallbackChargeSlot("code-428", label: "label-18")
        item.status = RevenueCycle.FallbackChargeSlotStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.FallbackChargeSlotStatus.requested) }
    }
}
