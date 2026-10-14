@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultHandoffDraftTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newDefaultHandoffDraft("code-765", title: "title-784")
        #expect(item.status == ClinicalOps.DefaultHandoffDraftStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = ClinicalOps.newDefaultHandoffDraft("code-765", title: "title-784")
        try item.moveTo(ClinicalOps.DefaultHandoffDraftStatus.granted)
        #expect(item.status == ClinicalOps.DefaultHandoffDraftStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newDefaultHandoffDraft("code-765", title: "title-784")
        item.status = ClinicalOps.DefaultHandoffDraftStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.DefaultHandoffDraftStatus.requested) }
    }
}
