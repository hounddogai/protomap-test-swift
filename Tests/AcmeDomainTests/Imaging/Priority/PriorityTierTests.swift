@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityTierTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newPriorityTier("code-729", label: "label-308")
        #expect(item.status == Imaging.PriorityTierStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Imaging.newPriorityTier("code-729", label: "label-308")
        try item.moveTo(Imaging.PriorityTierStatus.inProgress)
        #expect(item.status == Imaging.PriorityTierStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newPriorityTier("code-729", label: "label-308")
        item.status = Imaging.PriorityTierStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PriorityTierStatus.planned) }
    }
}
