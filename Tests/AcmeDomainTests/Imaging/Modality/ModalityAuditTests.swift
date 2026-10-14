@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityAuditTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newModalityAudit("code-974", title: "title-933")
        #expect(item.status == Imaging.ModalityAuditStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Imaging.newModalityAudit("code-974", title: "title-933")
        try item.moveTo(Imaging.ModalityAuditStatus.ready)
        #expect(item.status == Imaging.ModalityAuditStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newModalityAudit("code-974", title: "title-933")
        item.status = Imaging.ModalityAuditStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityAuditStatus.idle) }
    }
}
