@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledAccessionTargetTests {
    @Test func startsInProposed() throws {
        let item = Labs.newScheduledAccessionTarget("code-30", label: "label-600")
        #expect(item.status == Labs.ScheduledAccessionTargetStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Labs.newScheduledAccessionTarget("code-30", label: "label-600")
        try item.moveTo(Labs.ScheduledAccessionTargetStatus.rejected)
        #expect(item.status == Labs.ScheduledAccessionTargetStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newScheduledAccessionTarget("code-30", label: "label-600")
        item.status = Labs.ScheduledAccessionTargetStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ScheduledAccessionTargetStatus.proposed) }
    }
}
