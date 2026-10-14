@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackCareProtocolAuditTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newFallbackCareProtocolAudit("code-109", title: "title-931")
        #expect(item.status == Imaging.FallbackCareProtocolAuditStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Imaging.newFallbackCareProtocolAudit("code-109", title: "title-931")
        try item.moveTo(Imaging.FallbackCareProtocolAuditStatus.suspended)
        #expect(item.status == Imaging.FallbackCareProtocolAuditStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newFallbackCareProtocolAudit("code-109", title: "title-931")
        item.status = Imaging.FallbackCareProtocolAuditStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.FallbackCareProtocolAuditStatus.draft) }
    }
}
