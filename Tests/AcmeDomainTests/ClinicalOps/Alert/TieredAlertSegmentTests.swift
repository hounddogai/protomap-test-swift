@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredAlertSegmentTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newTieredAlertSegment("code-896", label: "label-406")
        #expect(item.status == ClinicalOps.TieredAlertSegmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = ClinicalOps.newTieredAlertSegment("code-896", label: "label-406")
        try item.moveTo(ClinicalOps.TieredAlertSegmentStatus.ready)
        #expect(item.status == ClinicalOps.TieredAlertSegmentStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newTieredAlertSegment("code-896", label: "label-406")
        item.status = ClinicalOps.TieredAlertSegmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TieredAlertSegmentStatus.idle) }
    }
}
