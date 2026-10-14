@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedModalityProfileTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newWeightedModalityProfile("code-330", name: "name-692")
        #expect(item.status == Imaging.WeightedModalityProfileStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Imaging.newWeightedModalityProfile("code-330", name: "name-692")
        try item.moveTo(Imaging.WeightedModalityProfileStatus.granted)
        #expect(item.status == Imaging.WeightedModalityProfileStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newWeightedModalityProfile("code-330", name: "name-692")
        item.status = Imaging.WeightedModalityProfileStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WeightedModalityProfileStatus.requested) }
    }
}
