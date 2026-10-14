@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictAuthorizationSlotTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newStrictAuthorizationSlot("code-733", title: "title-21")
        #expect(item.status == RevenueCycle.StrictAuthorizationSlotStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = RevenueCycle.newStrictAuthorizationSlot("code-733", title: "title-21")
        try item.moveTo(RevenueCycle.StrictAuthorizationSlotStatus.validated)
        #expect(item.status == RevenueCycle.StrictAuthorizationSlotStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newStrictAuthorizationSlot("code-733", title: "title-21")
        item.status = RevenueCycle.StrictAuthorizationSlotStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StrictAuthorizationSlotStatus.created) }
    }
}
