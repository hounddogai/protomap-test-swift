@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingAlertNoticeTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newRollingAlertNotice("code-833", name: "name-119")
        #expect(item.status == ClinicalOps.RollingAlertNoticeStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = ClinicalOps.newRollingAlertNotice("code-833", name: "name-119")
        try item.moveTo(ClinicalOps.RollingAlertNoticeStatus.warming)
        #expect(item.status == ClinicalOps.RollingAlertNoticeStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newRollingAlertNotice("code-833", name: "name-119")
        item.status = ClinicalOps.RollingAlertNoticeStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RollingAlertNoticeStatus.idle) }
    }
}
