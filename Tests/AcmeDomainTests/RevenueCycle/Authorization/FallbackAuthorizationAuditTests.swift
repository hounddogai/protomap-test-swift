@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackAuthorizationAuditTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newFallbackAuthorizationAudit("code-231", name: "name-983")
        #expect(item.status == RevenueCycle.FallbackAuthorizationAuditStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = RevenueCycle.newFallbackAuthorizationAudit("code-231", name: "name-983")
        try item.moveTo(RevenueCycle.FallbackAuthorizationAuditStatus.queued)
        #expect(item.status == RevenueCycle.FallbackAuthorizationAuditStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newFallbackAuthorizationAudit("code-231", name: "name-983")
        item.status = RevenueCycle.FallbackAuthorizationAuditStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.FallbackAuthorizationAuditStatus.new) }
    }
}
