@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationAuditTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newAuthorizationAudit("code-740", label: "label-110")
        #expect(item.status == RevenueCycle.AuthorizationAuditStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = RevenueCycle.newAuthorizationAudit("code-740", label: "label-110")
        try item.moveTo(RevenueCycle.AuthorizationAuditStatus.published)
        #expect(item.status == RevenueCycle.AuthorizationAuditStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newAuthorizationAudit("code-740", label: "label-110")
        item.status = RevenueCycle.AuthorizationAuditStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationAuditStatus.created) }
    }
}
