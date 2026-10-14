@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultRoundingDraftTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newDefaultRoundingDraft("code-253", label: "label-461")
        #expect(item.status == ClinicalOps.DefaultRoundingDraftStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = ClinicalOps.newDefaultRoundingDraft("code-253", label: "label-461")
        try item.moveTo(ClinicalOps.DefaultRoundingDraftStatus.reopened)
        #expect(item.status == ClinicalOps.DefaultRoundingDraftStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newDefaultRoundingDraft("code-253", label: "label-461")
        item.status = ClinicalOps.DefaultRoundingDraftStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.DefaultRoundingDraftStatus.`open`) }
    }
}
