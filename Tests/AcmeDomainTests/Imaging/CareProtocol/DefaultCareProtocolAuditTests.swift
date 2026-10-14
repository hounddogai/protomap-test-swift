@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingDefaultCareProtocolAuditTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newDefaultCareProtocolAudit("code-821", title: "title-470")
        #expect(item.status == Imaging.DefaultCareProtocolAuditStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Imaging.newDefaultCareProtocolAudit("code-821", title: "title-470")
        try item.moveTo(Imaging.DefaultCareProtocolAuditStatus.warming)
        #expect(item.status == Imaging.DefaultCareProtocolAuditStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newDefaultCareProtocolAudit("code-821", title: "title-470")
        item.status = Imaging.DefaultCareProtocolAuditStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.DefaultCareProtocolAuditStatus.idle) }
    }
}
