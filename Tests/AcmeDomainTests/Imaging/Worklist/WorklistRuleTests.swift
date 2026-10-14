@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistRuleTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newWorklistRule("code-193", name: "name-612")
        #expect(item.status == Imaging.WorklistRuleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Imaging.newWorklistRule("code-193", name: "name-612")
        try item.moveTo(Imaging.WorklistRuleStatus.stopped)
        #expect(item.status == Imaging.WorklistRuleStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newWorklistRule("code-193", name: "name-612")
        item.status = Imaging.WorklistRuleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WorklistRuleStatus.idle) }
    }
}
