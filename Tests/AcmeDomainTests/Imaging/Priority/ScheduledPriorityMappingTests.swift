@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledPriorityMappingTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newScheduledPriorityMapping("code-177", title: "title-1")
        #expect(item.status == Imaging.ScheduledPriorityMappingStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Imaging.newScheduledPriorityMapping("code-177", title: "title-1")
        try item.moveTo(Imaging.ScheduledPriorityMappingStatus.granted)
        #expect(item.status == Imaging.ScheduledPriorityMappingStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newScheduledPriorityMapping("code-177", title: "title-1")
        item.status = Imaging.ScheduledPriorityMappingStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ScheduledPriorityMappingStatus.requested) }
    }
}
