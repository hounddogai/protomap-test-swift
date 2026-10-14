@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackRemittanceClaimTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newFallbackRemittanceClaim("code-315", label: "label-461")
        #expect(item.status == RevenueCycle.FallbackRemittanceClaimStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = RevenueCycle.newFallbackRemittanceClaim("code-315", label: "label-461")
        try item.moveTo(RevenueCycle.FallbackRemittanceClaimStatus.closed)
        #expect(item.status == RevenueCycle.FallbackRemittanceClaimStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newFallbackRemittanceClaim("code-315", label: "label-461")
        item.status = RevenueCycle.FallbackRemittanceClaimStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.FallbackRemittanceClaimStatus.draft) }
    }
}
