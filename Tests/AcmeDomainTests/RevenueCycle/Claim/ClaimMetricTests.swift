@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimMetricTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newClaimMetric("code-413", name: "name-454")
        #expect(item.status == RevenueCycle.ClaimMetricStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = RevenueCycle.newClaimMetric("code-413", name: "name-454")
        try item.moveTo(RevenueCycle.ClaimMetricStatus.granted)
        #expect(item.status == RevenueCycle.ClaimMetricStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newClaimMetric("code-413", name: "name-454")
        item.status = RevenueCycle.ClaimMetricStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimMetricStatus.requested) }
    }
}
