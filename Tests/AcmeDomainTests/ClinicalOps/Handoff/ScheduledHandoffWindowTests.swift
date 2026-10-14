@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledHandoffWindowTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newScheduledHandoffWindow("code-818", label: "label-367")
        #expect(item.status == ClinicalOps.ScheduledHandoffWindowStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = ClinicalOps.newScheduledHandoffWindow("code-818", label: "label-367")
        try item.moveTo(ClinicalOps.ScheduledHandoffWindowStatus.granted)
        #expect(item.status == ClinicalOps.ScheduledHandoffWindowStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newScheduledHandoffWindow("code-818", label: "label-367")
        item.status = ClinicalOps.ScheduledHandoffWindowStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.ScheduledHandoffWindowStatus.requested) }
    }
}
