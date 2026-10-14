@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyModalityThresholdTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newLegacyModalityThreshold("code-84", name: "name-656")
        #expect(item.status == Imaging.LegacyModalityThresholdStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Imaging.newLegacyModalityThreshold("code-84", name: "name-656")
        try item.moveTo(Imaging.LegacyModalityThresholdStatus.approved)
        #expect(item.status == Imaging.LegacyModalityThresholdStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newLegacyModalityThreshold("code-84", name: "name-656")
        item.status = Imaging.LegacyModalityThresholdStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.LegacyModalityThresholdStatus.proposed) }
    }
}
