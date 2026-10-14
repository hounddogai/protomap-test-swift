@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackAuthorizationClaimTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newFallbackAuthorizationClaim("code-37", title: "title-540")
        #expect(item.status == RevenueCycle.FallbackAuthorizationClaimStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = RevenueCycle.newFallbackAuthorizationClaim("code-37", title: "title-540")
        try item.moveTo(RevenueCycle.FallbackAuthorizationClaimStatus.archived)
        #expect(item.status == RevenueCycle.FallbackAuthorizationClaimStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newFallbackAuthorizationClaim("code-37", title: "title-540")
        item.status = RevenueCycle.FallbackAuthorizationClaimStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.FallbackAuthorizationClaimStatus.`open`) }
    }
}
