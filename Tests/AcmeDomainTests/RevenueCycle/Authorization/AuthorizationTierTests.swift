@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationTierTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newAuthorizationTier("code-530", title: "title-940")
        #expect(item.status == RevenueCycle.AuthorizationTierStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = RevenueCycle.newAuthorizationTier("code-530", title: "title-940")
        try item.moveTo(RevenueCycle.AuthorizationTierStatus.validated)
        #expect(item.status == RevenueCycle.AuthorizationTierStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newAuthorizationTier("code-530", title: "title-940")
        item.status = RevenueCycle.AuthorizationTierStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationTierStatus.created) }
    }
}
