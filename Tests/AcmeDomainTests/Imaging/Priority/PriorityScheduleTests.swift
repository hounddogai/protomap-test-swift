@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityScheduleTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newPrioritySchedule("code-913", label: "label-712")
        #expect(item.status == Imaging.PriorityScheduleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Imaging.newPrioritySchedule("code-913", label: "label-712")
        try item.moveTo(Imaging.PriorityScheduleStatus.published)
        #expect(item.status == Imaging.PriorityScheduleStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newPrioritySchedule("code-913", label: "label-712")
        item.status = Imaging.PriorityScheduleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PriorityScheduleStatus.created) }
    }
}
