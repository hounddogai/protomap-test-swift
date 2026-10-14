@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationSlotTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newAuthorizationSlot("code-827", label: "label-608")
        #expect(item.status == RevenueCycle.AuthorizationSlotStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = RevenueCycle.newAuthorizationSlot("code-827", label: "label-608")
        try item.moveTo(RevenueCycle.AuthorizationSlotStatus.draining)
        #expect(item.status == RevenueCycle.AuthorizationSlotStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newAuthorizationSlot("code-827", label: "label-608")
        item.status = RevenueCycle.AuthorizationSlotStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationSlotStatus.idle) }
    }
}
