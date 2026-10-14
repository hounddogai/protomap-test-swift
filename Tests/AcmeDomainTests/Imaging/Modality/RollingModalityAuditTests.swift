@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingModalityAuditTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newRollingModalityAudit("code-218", title: "title-495")
        #expect(item.status == Imaging.RollingModalityAuditStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Imaging.newRollingModalityAudit("code-218", title: "title-495")
        try item.moveTo(Imaging.RollingModalityAuditStatus.revoked)
        #expect(item.status == Imaging.RollingModalityAuditStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newRollingModalityAudit("code-218", title: "title-495")
        item.status = Imaging.RollingModalityAuditStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.RollingModalityAuditStatus.requested) }
    }
}
