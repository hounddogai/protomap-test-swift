@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimScoreTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newClaimScore("code-944", title: "title-801")
        #expect(item.status == RevenueCycle.ClaimScoreStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = RevenueCycle.newClaimScore("code-944", title: "title-801")
        try item.moveTo(RevenueCycle.ClaimScoreStatus.suspended)
        #expect(item.status == RevenueCycle.ClaimScoreStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newClaimScore("code-944", title: "title-801")
        item.status = RevenueCycle.ClaimScoreStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimScoreStatus.draft) }
    }
}
