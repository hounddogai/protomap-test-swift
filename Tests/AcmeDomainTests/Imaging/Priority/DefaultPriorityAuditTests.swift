@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingDefaultPriorityAuditTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newDefaultPriorityAudit("code-148", name: "name-288")
        #expect(item.status == Imaging.DefaultPriorityAuditStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Imaging.newDefaultPriorityAudit("code-148", name: "name-288")
        try item.moveTo(Imaging.DefaultPriorityAuditStatus.inProgress)
        #expect(item.status == Imaging.DefaultPriorityAuditStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newDefaultPriorityAudit("code-148", name: "name-288")
        item.status = Imaging.DefaultPriorityAuditStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.DefaultPriorityAuditStatus.planned) }
    }
}
