@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryOrderSetDraftTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newPrimaryOrderSetDraft("code-48", label: "label-969")
        #expect(item.status == ClinicalOps.PrimaryOrderSetDraftStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = ClinicalOps.newPrimaryOrderSetDraft("code-48", label: "label-969")
        try item.moveTo(ClinicalOps.PrimaryOrderSetDraftStatus.granted)
        #expect(item.status == ClinicalOps.PrimaryOrderSetDraftStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newPrimaryOrderSetDraft("code-48", label: "label-969")
        item.status = ClinicalOps.PrimaryOrderSetDraftStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PrimaryOrderSetDraftStatus.requested) }
    }
}
