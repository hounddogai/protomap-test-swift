@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingDraftTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newRoundingDraft("code-551", title: "title-784")
        #expect(item.status == ClinicalOps.RoundingDraftStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = ClinicalOps.newRoundingDraft("code-551", title: "title-784")
        try item.moveTo(ClinicalOps.RoundingDraftStatus.closed)
        #expect(item.status == ClinicalOps.RoundingDraftStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newRoundingDraft("code-551", title: "title-784")
        item.status = ClinicalOps.RoundingDraftStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingDraftStatus.draft) }
    }
}
