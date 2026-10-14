@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedModalityTierTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newWeightedModalityTier("code-52", name: "name-156")
        #expect(item.status == Imaging.WeightedModalityTierStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Imaging.newWeightedModalityTier("code-52", name: "name-156")
        try item.moveTo(Imaging.WeightedModalityTierStatus.completed)
        #expect(item.status == Imaging.WeightedModalityTierStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newWeightedModalityTier("code-52", name: "name-156")
        item.status = Imaging.WeightedModalityTierStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WeightedModalityTierStatus.planned) }
    }
}
