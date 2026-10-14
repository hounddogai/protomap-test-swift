@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationMetricTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newAuthorizationMetric("code-945", title: "title-715")
        #expect(item.status == RevenueCycle.AuthorizationMetricStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = RevenueCycle.newAuthorizationMetric("code-945", title: "title-715")
        try item.moveTo(RevenueCycle.AuthorizationMetricStatus.revoked)
        #expect(item.status == RevenueCycle.AuthorizationMetricStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newAuthorizationMetric("code-945", title: "title-715")
        item.status = RevenueCycle.AuthorizationMetricStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationMetricStatus.requested) }
    }
}
