@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialSlotTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newDenialSlot("code-251", label: "label-244")
        #expect(item.status == RevenueCycle.DenialSlotStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = RevenueCycle.newDenialSlot("code-251", label: "label-244")
        try item.moveTo(RevenueCycle.DenialSlotStatus.rejected)
        #expect(item.status == RevenueCycle.DenialSlotStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newDenialSlot("code-251", label: "label-244")
        item.status = RevenueCycle.DenialSlotStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialSlotStatus.proposed) }
    }
}
