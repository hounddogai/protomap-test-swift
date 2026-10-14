@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictHandoffDraftTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newStrictHandoffDraft("code-603", label: "label-326")
        #expect(item.status == ClinicalOps.StrictHandoffDraftStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = ClinicalOps.newStrictHandoffDraft("code-603", label: "label-326")
        try item.moveTo(ClinicalOps.StrictHandoffDraftStatus.revoked)
        #expect(item.status == ClinicalOps.StrictHandoffDraftStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newStrictHandoffDraft("code-603", label: "label-326")
        item.status = ClinicalOps.StrictHandoffDraftStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.StrictHandoffDraftStatus.requested) }
    }
}
