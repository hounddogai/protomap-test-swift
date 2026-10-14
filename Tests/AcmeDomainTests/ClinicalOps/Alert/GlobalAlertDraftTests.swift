@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalAlertDraftTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newGlobalAlertDraft("code-729", name: "name-381")
        #expect(item.status == ClinicalOps.GlobalAlertDraftStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = ClinicalOps.newGlobalAlertDraft("code-729", name: "name-381")
        try item.moveTo(ClinicalOps.GlobalAlertDraftStatus.queued)
        #expect(item.status == ClinicalOps.GlobalAlertDraftStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newGlobalAlertDraft("code-729", name: "name-381")
        item.status = ClinicalOps.GlobalAlertDraftStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.GlobalAlertDraftStatus.new) }
    }
}
