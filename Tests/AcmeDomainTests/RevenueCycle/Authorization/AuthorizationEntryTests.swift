@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationEntryTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newAuthorizationEntry("code-796", name: "name-248")
        #expect(item.status == RevenueCycle.AuthorizationEntryStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = RevenueCycle.newAuthorizationEntry("code-796", name: "name-248")
        try item.moveTo(RevenueCycle.AuthorizationEntryStatus.approved)
        #expect(item.status == RevenueCycle.AuthorizationEntryStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newAuthorizationEntry("code-796", name: "name-248")
        item.status = RevenueCycle.AuthorizationEntryStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationEntryStatus.proposed) }
    }
}
