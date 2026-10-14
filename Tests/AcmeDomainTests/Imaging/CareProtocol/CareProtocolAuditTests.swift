@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolAuditTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newCareProtocolAudit("code-682", title: "title-645")
        #expect(item.status == Imaging.CareProtocolAuditStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Imaging.newCareProtocolAudit("code-682", title: "title-645")
        try item.moveTo(Imaging.CareProtocolAuditStatus.pending)
        #expect(item.status == Imaging.CareProtocolAuditStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newCareProtocolAudit("code-682", title: "title-645")
        item.status = Imaging.CareProtocolAuditStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolAuditStatus.draft) }
    }
}
