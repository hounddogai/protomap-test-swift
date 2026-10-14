@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenMilestoneTests {
    @Test func startsInIdle() throws {
        let item = Labs.newSpecimenMilestone("code-151", label: "label-707")
        #expect(item.status == Labs.SpecimenMilestoneStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Labs.newSpecimenMilestone("code-151", label: "label-707")
        try item.moveTo(Labs.SpecimenMilestoneStatus.ready)
        #expect(item.status == Labs.SpecimenMilestoneStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newSpecimenMilestone("code-151", label: "label-707")
        item.status = Labs.SpecimenMilestoneStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenMilestoneStatus.idle) }
    }
}
