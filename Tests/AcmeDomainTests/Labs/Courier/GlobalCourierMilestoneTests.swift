@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalCourierMilestoneTests {
    @Test func startsInNew() throws {
        let item = Labs.newGlobalCourierMilestone("code-597", label: "label-270")
        #expect(item.status == Labs.GlobalCourierMilestoneStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Labs.newGlobalCourierMilestone("code-597", label: "label-270")
        try item.moveTo(Labs.GlobalCourierMilestoneStatus.failed)
        #expect(item.status == Labs.GlobalCourierMilestoneStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newGlobalCourierMilestone("code-597", label: "label-270")
        item.status = Labs.GlobalCourierMilestoneStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.GlobalCourierMilestoneStatus.new) }
    }
}
