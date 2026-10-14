@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityAssignmentTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newPriorityAssignment("code-894", label: "label-663")
        #expect(item.status == Imaging.PriorityAssignmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Imaging.newPriorityAssignment("code-894", label: "label-663")
        try item.moveTo(Imaging.PriorityAssignmentStatus.approved)
        #expect(item.status == Imaging.PriorityAssignmentStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newPriorityAssignment("code-894", label: "label-663")
        item.status = Imaging.PriorityAssignmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PriorityAssignmentStatus.proposed) }
    }
}
