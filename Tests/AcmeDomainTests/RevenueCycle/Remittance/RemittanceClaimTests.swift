@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceClaimTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newRemittanceClaim("code-217", label: "label-820")
        #expect(item.status == RevenueCycle.RemittanceClaimStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = RevenueCycle.newRemittanceClaim("code-217", label: "label-820")
        try item.moveTo(RevenueCycle.RemittanceClaimStatus.pending)
        #expect(item.status == RevenueCycle.RemittanceClaimStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newRemittanceClaim("code-217", label: "label-820")
        item.status = RevenueCycle.RemittanceClaimStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceClaimStatus.draft) }
    }
}
