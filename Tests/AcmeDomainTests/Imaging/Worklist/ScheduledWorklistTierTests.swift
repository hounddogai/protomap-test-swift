@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledWorklistTierTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newScheduledWorklistTier("code-535", title: "title-908")
        #expect(item.status == Imaging.ScheduledWorklistTierStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Imaging.newScheduledWorklistTier("code-535", title: "title-908")
        try item.moveTo(Imaging.ScheduledWorklistTierStatus.draining)
        #expect(item.status == Imaging.ScheduledWorklistTierStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newScheduledWorklistTier("code-535", title: "title-908")
        item.status = Imaging.ScheduledWorklistTierStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ScheduledWorklistTierStatus.idle) }
    }
}
