@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationGroupTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newAuthorizationGroup("code-379", label: "label-424")
        #expect(item.status == RevenueCycle.AuthorizationGroupStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = RevenueCycle.newAuthorizationGroup("code-379", label: "label-424")
        try item.moveTo(RevenueCycle.AuthorizationGroupStatus.published)
        #expect(item.status == RevenueCycle.AuthorizationGroupStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newAuthorizationGroup("code-379", label: "label-424")
        item.status = RevenueCycle.AuthorizationGroupStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationGroupStatus.created) }
    }
}
