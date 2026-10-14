@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackClaimDigestTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newFallbackClaimDigest("code-393", label: "label-442")
        #expect(item.status == RevenueCycle.FallbackClaimDigestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = RevenueCycle.newFallbackClaimDigest("code-393", label: "label-442")
        try item.moveTo(RevenueCycle.FallbackClaimDigestStatus.running)
        #expect(item.status == RevenueCycle.FallbackClaimDigestStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newFallbackClaimDigest("code-393", label: "label-442")
        item.status = RevenueCycle.FallbackClaimDigestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.FallbackClaimDigestStatus.new) }
    }
}
