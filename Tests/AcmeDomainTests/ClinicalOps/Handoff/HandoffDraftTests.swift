@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffDraftTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newHandoffDraft("code-789", label: "label-831")
        #expect(item.status == ClinicalOps.HandoffDraftStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = ClinicalOps.newHandoffDraft("code-789", label: "label-831")
        try item.moveTo(ClinicalOps.HandoffDraftStatus.resolved)
        #expect(item.status == ClinicalOps.HandoffDraftStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newHandoffDraft("code-789", label: "label-831")
        item.status = ClinicalOps.HandoffDraftStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.HandoffDraftStatus.`open`) }
    }
}
