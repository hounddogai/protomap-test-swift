@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledPriorityAllocationTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newScheduledPriorityAllocation("code-802", name: "name-504")
        #expect(item.status == Imaging.ScheduledPriorityAllocationStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Imaging.newScheduledPriorityAllocation("code-802", name: "name-504")
        try item.moveTo(Imaging.ScheduledPriorityAllocationStatus.inReview)
        #expect(item.status == Imaging.ScheduledPriorityAllocationStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newScheduledPriorityAllocation("code-802", name: "name-504")
        item.status = Imaging.ScheduledPriorityAllocationStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ScheduledPriorityAllocationStatus.`open`) }
    }
}
