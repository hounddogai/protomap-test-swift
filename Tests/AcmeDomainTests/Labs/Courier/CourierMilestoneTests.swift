@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierMilestoneTests {
    @Test func startsInRequested() throws {
        let item = Labs.newCourierMilestone("code-210", label: "label-642")
        #expect(item.status == Labs.CourierMilestoneStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Labs.newCourierMilestone("code-210", label: "label-642")
        try item.moveTo(Labs.CourierMilestoneStatus.expired)
        #expect(item.status == Labs.CourierMilestoneStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newCourierMilestone("code-210", label: "label-642")
        item.status = Labs.CourierMilestoneStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierMilestoneStatus.requested) }
    }
}
