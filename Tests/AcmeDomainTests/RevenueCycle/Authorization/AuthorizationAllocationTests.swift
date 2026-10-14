@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationAllocationTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newAuthorizationAllocation("code-117", name: "name-252")
        #expect(item.status == RevenueCycle.AuthorizationAllocationStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = RevenueCycle.newAuthorizationAllocation("code-117", name: "name-252")
        try item.moveTo(RevenueCycle.AuthorizationAllocationStatus.active)
        #expect(item.status == RevenueCycle.AuthorizationAllocationStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newAuthorizationAllocation("code-117", name: "name-252")
        item.status = RevenueCycle.AuthorizationAllocationStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationAllocationStatus.draft) }
    }
}
