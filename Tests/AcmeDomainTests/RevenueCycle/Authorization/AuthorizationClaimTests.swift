@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationClaimTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newAuthorizationClaim("code-770", name: "name-954")
        #expect(item.status == RevenueCycle.AuthorizationClaimStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = RevenueCycle.newAuthorizationClaim("code-770", name: "name-954")
        try item.moveTo(RevenueCycle.AuthorizationClaimStatus.validated)
        #expect(item.status == RevenueCycle.AuthorizationClaimStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newAuthorizationClaim("code-770", name: "name-954")
        item.status = RevenueCycle.AuthorizationClaimStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationClaimStatus.created) }
    }
}
