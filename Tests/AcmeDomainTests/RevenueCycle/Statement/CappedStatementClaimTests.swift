@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedStatementClaimTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newCappedStatementClaim("code-125", name: "name-222")
        #expect(item.status == RevenueCycle.CappedStatementClaimStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = RevenueCycle.newCappedStatementClaim("code-125", name: "name-222")
        try item.moveTo(RevenueCycle.CappedStatementClaimStatus.pending)
        #expect(item.status == RevenueCycle.CappedStatementClaimStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newCappedStatementClaim("code-125", name: "name-222")
        item.status = RevenueCycle.CappedStatementClaimStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.CappedStatementClaimStatus.draft) }
    }
}
