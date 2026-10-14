@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimDraftTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newClaimDraft("code-73", title: "title-411")
        #expect(item.status == RevenueCycle.ClaimDraftStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = RevenueCycle.newClaimDraft("code-73", title: "title-411")
        try item.moveTo(RevenueCycle.ClaimDraftStatus.retired)
        #expect(item.status == RevenueCycle.ClaimDraftStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newClaimDraft("code-73", title: "title-411")
        item.status = RevenueCycle.ClaimDraftStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimDraftStatus.created) }
    }
}
