@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientRemittanceSlotTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newLenientRemittanceSlot("code-452", title: "title-731")
        #expect(item.status == RevenueCycle.LenientRemittanceSlotStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = RevenueCycle.newLenientRemittanceSlot("code-452", title: "title-731")
        try item.moveTo(RevenueCycle.LenientRemittanceSlotStatus.validated)
        #expect(item.status == RevenueCycle.LenientRemittanceSlotStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newLenientRemittanceSlot("code-452", title: "title-731")
        item.status = RevenueCycle.LenientRemittanceSlotStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.LenientRemittanceSlotStatus.created) }
    }
}
