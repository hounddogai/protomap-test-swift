@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureTemplateTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newClosureTemplate("code-784", label: "label-682")
        #expect(item.status == Referrals.ClosureTemplateStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Referrals.newClosureTemplate("code-784", label: "label-682")
        try item.moveTo(Referrals.ClosureTemplateStatus.suspended)
        #expect(item.status == Referrals.ClosureTemplateStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newClosureTemplate("code-784", label: "label-682")
        item.status = Referrals.ClosureTemplateStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosureTemplateStatus.draft) }
    }
}
