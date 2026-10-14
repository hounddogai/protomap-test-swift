@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveAuthorizationAuditTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newAdaptiveAuthorizationAudit("code-423", title: "title-542")
        #expect(item.status == RevenueCycle.AdaptiveAuthorizationAuditStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = RevenueCycle.newAdaptiveAuthorizationAudit("code-423", title: "title-542")
        try item.moveTo(RevenueCycle.AdaptiveAuthorizationAuditStatus.published)
        #expect(item.status == RevenueCycle.AdaptiveAuthorizationAuditStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newAdaptiveAuthorizationAudit("code-423", title: "title-542")
        item.status = RevenueCycle.AdaptiveAuthorizationAuditStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AdaptiveAuthorizationAuditStatus.created) }
    }
}
