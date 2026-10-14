@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledModalityAuditTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newScheduledModalityAudit("code-208", title: "title-714")
        #expect(item.status == Imaging.ScheduledModalityAuditStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Imaging.newScheduledModalityAudit("code-208", title: "title-714")
        try item.moveTo(Imaging.ScheduledModalityAuditStatus.withdrawn)
        #expect(item.status == Imaging.ScheduledModalityAuditStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newScheduledModalityAudit("code-208", title: "title-714")
        item.status = Imaging.ScheduledModalityAuditStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ScheduledModalityAuditStatus.proposed) }
    }
}
