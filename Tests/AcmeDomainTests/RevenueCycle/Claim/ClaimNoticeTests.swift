@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimNoticeTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newClaimNotice("code-562", title: "title-258")
        #expect(item.status == RevenueCycle.ClaimNoticeStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = RevenueCycle.newClaimNotice("code-562", title: "title-258")
        try item.moveTo(RevenueCycle.ClaimNoticeStatus.rejected)
        #expect(item.status == RevenueCycle.ClaimNoticeStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newClaimNotice("code-562", title: "title-258")
        item.status = RevenueCycle.ClaimNoticeStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimNoticeStatus.proposed) }
    }
}
