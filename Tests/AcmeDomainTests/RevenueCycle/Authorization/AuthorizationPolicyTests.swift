@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationPolicyTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newAuthorizationPolicy("code-637", name: "name-382")
        #expect(item.status == RevenueCycle.AuthorizationPolicyStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = RevenueCycle.newAuthorizationPolicy("code-637", name: "name-382")
        try item.moveTo(RevenueCycle.AuthorizationPolicyStatus.reopened)
        #expect(item.status == RevenueCycle.AuthorizationPolicyStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newAuthorizationPolicy("code-637", name: "name-382")
        item.status = RevenueCycle.AuthorizationPolicyStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationPolicyStatus.`open`) }
    }
}
