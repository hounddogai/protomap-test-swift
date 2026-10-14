@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualModalityEstimateTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newManualModalityEstimate("code-846", label: "label-238")
        #expect(item.status == Imaging.ManualModalityEstimateStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Imaging.newManualModalityEstimate("code-846", label: "label-238")
        try item.moveTo(Imaging.ManualModalityEstimateStatus.granted)
        #expect(item.status == Imaging.ManualModalityEstimateStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newManualModalityEstimate("code-846", label: "label-238")
        item.status = Imaging.ManualModalityEstimateStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ManualModalityEstimateStatus.requested) }
    }
}
