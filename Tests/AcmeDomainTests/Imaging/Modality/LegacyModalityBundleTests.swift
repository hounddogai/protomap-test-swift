@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyModalityBundleTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newLegacyModalityBundle("code-772", name: "name-141")
        #expect(item.status == Imaging.LegacyModalityBundleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Imaging.newLegacyModalityBundle("code-772", name: "name-141")
        try item.moveTo(Imaging.LegacyModalityBundleStatus.rejected)
        #expect(item.status == Imaging.LegacyModalityBundleStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newLegacyModalityBundle("code-772", name: "name-141")
        item.status = Imaging.LegacyModalityBundleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.LegacyModalityBundleStatus.proposed) }
    }
}
