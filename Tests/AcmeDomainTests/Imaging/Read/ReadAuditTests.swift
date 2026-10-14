@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadAuditTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newReadAudit("code-417", label: "label-38")
        #expect(item.status == Imaging.ReadAuditStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Imaging.newReadAudit("code-417", label: "label-38")
        try item.moveTo(Imaging.ReadAuditStatus.ready)
        #expect(item.status == Imaging.ReadAuditStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newReadAudit("code-417", label: "label-38")
        item.status = Imaging.ReadAuditStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ReadAuditStatus.idle) }
    }
}
