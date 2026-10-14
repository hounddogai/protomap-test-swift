@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertOverrideTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newAlertOverride("code-73", title: "title-961")
        #expect(item.status == ClinicalOps.AlertOverrideStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = ClinicalOps.newAlertOverride("code-73", title: "title-961")
        try item.moveTo(ClinicalOps.AlertOverrideStatus.granted)
        #expect(item.status == ClinicalOps.AlertOverrideStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newAlertOverride("code-73", title: "title-961")
        item.status = ClinicalOps.AlertOverrideStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertOverrideStatus.requested) }
    }
}
