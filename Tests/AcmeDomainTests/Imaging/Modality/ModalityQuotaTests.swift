@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityQuotaTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newModalityQuota("code-277", title: "title-160")
        #expect(item.status == Imaging.ModalityQuotaStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Imaging.newModalityQuota("code-277", title: "title-160")
        try item.moveTo(Imaging.ModalityQuotaStatus.warming)
        #expect(item.status == Imaging.ModalityQuotaStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newModalityQuota("code-277", title: "title-160")
        item.status = Imaging.ModalityQuotaStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityQuotaStatus.idle) }
    }
}
