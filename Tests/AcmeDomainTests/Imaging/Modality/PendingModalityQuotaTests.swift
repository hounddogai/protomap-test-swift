@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingModalityQuotaTests {
    @Test func startsInNew() throws {
        let item = Imaging.newPendingModalityQuota("code-163", label: "label-515")
        #expect(item.status == Imaging.PendingModalityQuotaStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Imaging.newPendingModalityQuota("code-163", label: "label-515")
        try item.moveTo(Imaging.PendingModalityQuotaStatus.running)
        #expect(item.status == Imaging.PendingModalityQuotaStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newPendingModalityQuota("code-163", label: "label-515")
        item.status = Imaging.PendingModalityQuotaStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PendingModalityQuotaStatus.new) }
    }
}
