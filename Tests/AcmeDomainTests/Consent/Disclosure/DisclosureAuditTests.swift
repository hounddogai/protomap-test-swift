@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureAuditTests {
    @Test func startsInDraft() throws {
        let item = Consent.newDisclosureAudit("code-46", label: "label-456")
        #expect(item.status == Consent.DisclosureAuditStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Consent.newDisclosureAudit("code-46", label: "label-456")
        try item.moveTo(Consent.DisclosureAuditStatus.suspended)
        #expect(item.status == Consent.DisclosureAuditStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newDisclosureAudit("code-46", label: "label-456")
        item.status = Consent.DisclosureAuditStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureAuditStatus.draft) }
    }
}
