@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimSlotTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newClaimSlot("code-830", label: "label-754")
        #expect(item.status == RevenueCycle.ClaimSlotStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = RevenueCycle.newClaimSlot("code-830", label: "label-754")
        try item.moveTo(RevenueCycle.ClaimSlotStatus.queued)
        #expect(item.status == RevenueCycle.ClaimSlotStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newClaimSlot("code-830", label: "label-754")
        item.status = RevenueCycle.ClaimSlotStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimSlotStatus.new) }
    }
}
