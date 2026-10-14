@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingCareProtocolAuditTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newRollingCareProtocolAudit("code-628", label: "label-19")
        #expect(item.status == Imaging.RollingCareProtocolAuditStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Imaging.newRollingCareProtocolAudit("code-628", label: "label-19")
        try item.moveTo(Imaging.RollingCareProtocolAuditStatus.reopened)
        #expect(item.status == Imaging.RollingCareProtocolAuditStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newRollingCareProtocolAudit("code-628", label: "label-19")
        item.status = Imaging.RollingCareProtocolAuditStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.RollingCareProtocolAuditStatus.`open`) }
    }
}
