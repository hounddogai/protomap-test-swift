@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackStudySlotTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newFallbackStudySlot("code-179", title: "title-305")
        #expect(item.status == Imaging.FallbackStudySlotStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Imaging.newFallbackStudySlot("code-179", title: "title-305")
        try item.moveTo(Imaging.FallbackStudySlotStatus.draining)
        #expect(item.status == Imaging.FallbackStudySlotStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newFallbackStudySlot("code-179", title: "title-305")
        item.status = Imaging.FallbackStudySlotStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.FallbackStudySlotStatus.idle) }
    }
}
