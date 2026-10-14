@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptivePriorityClaimTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newAdaptivePriorityClaim("code-421", label: "label-252")
        #expect(item.status == Imaging.AdaptivePriorityClaimStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Imaging.newAdaptivePriorityClaim("code-421", label: "label-252")
        try item.moveTo(Imaging.AdaptivePriorityClaimStatus.stopped)
        #expect(item.status == Imaging.AdaptivePriorityClaimStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newAdaptivePriorityClaim("code-421", label: "label-252")
        item.status = Imaging.AdaptivePriorityClaimStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.AdaptivePriorityClaimStatus.idle) }
    }
}
