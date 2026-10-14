@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationOverrideTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newAuthorizationOverride("code-776", title: "title-927")
        #expect(item.status == RevenueCycle.AuthorizationOverrideStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = RevenueCycle.newAuthorizationOverride("code-776", title: "title-927")
        try item.moveTo(RevenueCycle.AuthorizationOverrideStatus.scheduled)
        #expect(item.status == RevenueCycle.AuthorizationOverrideStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newAuthorizationOverride("code-776", title: "title-927")
        item.status = RevenueCycle.AuthorizationOverrideStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationOverrideStatus.planned) }
    }
}
