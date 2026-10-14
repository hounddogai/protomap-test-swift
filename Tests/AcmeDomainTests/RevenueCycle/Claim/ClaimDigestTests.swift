@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimDigestTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newClaimDigest("code-453", label: "label-648")
        #expect(item.status == RevenueCycle.ClaimDigestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = RevenueCycle.newClaimDigest("code-453", label: "label-648")
        try item.moveTo(RevenueCycle.ClaimDigestStatus.pending)
        #expect(item.status == RevenueCycle.ClaimDigestStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newClaimDigest("code-453", label: "label-648")
        item.status = RevenueCycle.ClaimDigestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimDigestStatus.draft) }
    }
}
