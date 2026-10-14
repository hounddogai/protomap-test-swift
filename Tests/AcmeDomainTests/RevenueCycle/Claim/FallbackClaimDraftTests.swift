@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackClaimDraftTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newFallbackClaimDraft("code-666", title: "title-40")
        #expect(item.status == RevenueCycle.FallbackClaimDraftStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = RevenueCycle.newFallbackClaimDraft("code-666", title: "title-40")
        try item.moveTo(RevenueCycle.FallbackClaimDraftStatus.suspended)
        #expect(item.status == RevenueCycle.FallbackClaimDraftStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newFallbackClaimDraft("code-666", title: "title-40")
        item.status = RevenueCycle.FallbackClaimDraftStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.FallbackClaimDraftStatus.draft) }
    }
}
