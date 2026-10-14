@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolQuotaTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newCareProtocolQuota("code-556", label: "label-635")
        #expect(item.status == Imaging.CareProtocolQuotaStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Imaging.newCareProtocolQuota("code-556", label: "label-635")
        try item.moveTo(Imaging.CareProtocolQuotaStatus.suspended)
        #expect(item.status == Imaging.CareProtocolQuotaStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newCareProtocolQuota("code-556", label: "label-635")
        item.status = Imaging.CareProtocolQuotaStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolQuotaStatus.draft) }
    }
}
