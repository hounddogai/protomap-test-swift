@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictAuthorizationWindowTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newStrictAuthorizationWindow("code-678", title: "title-300")
        #expect(item.status == RevenueCycle.StrictAuthorizationWindowStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = RevenueCycle.newStrictAuthorizationWindow("code-678", title: "title-300")
        try item.moveTo(RevenueCycle.StrictAuthorizationWindowStatus.validated)
        #expect(item.status == RevenueCycle.StrictAuthorizationWindowStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newStrictAuthorizationWindow("code-678", title: "title-300")
        item.status = RevenueCycle.StrictAuthorizationWindowStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StrictAuthorizationWindowStatus.created) }
    }
}
