@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientSpecimenMilestoneTests {
    @Test func startsInProposed() throws {
        let item = Labs.newLenientSpecimenMilestone("code-847", label: "label-609")
        #expect(item.status == Labs.LenientSpecimenMilestoneStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Labs.newLenientSpecimenMilestone("code-847", label: "label-609")
        try item.moveTo(Labs.LenientSpecimenMilestoneStatus.rejected)
        #expect(item.status == Labs.LenientSpecimenMilestoneStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newLenientSpecimenMilestone("code-847", label: "label-609")
        item.status = Labs.LenientSpecimenMilestoneStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LenientSpecimenMilestoneStatus.proposed) }
    }
}
