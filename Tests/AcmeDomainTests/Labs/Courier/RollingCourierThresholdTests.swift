@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingCourierThresholdTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newRollingCourierThreshold("code-71", title: "title-488")
        #expect(item.status == Labs.RollingCourierThresholdStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Labs.newRollingCourierThreshold("code-71", title: "title-488")
        try item.moveTo(Labs.RollingCourierThresholdStatus.inProgress)
        #expect(item.status == Labs.RollingCourierThresholdStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newRollingCourierThreshold("code-71", title: "title-488")
        item.status = Labs.RollingCourierThresholdStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RollingCourierThresholdStatus.planned) }
    }
}
