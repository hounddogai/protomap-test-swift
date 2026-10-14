@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredModalityVarianceTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newTieredModalityVariance("code-866", name: "name-440")
        #expect(item.status == Imaging.TieredModalityVarianceStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Imaging.newTieredModalityVariance("code-866", name: "name-440")
        try item.moveTo(Imaging.TieredModalityVarianceStatus.rejected)
        #expect(item.status == Imaging.TieredModalityVarianceStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newTieredModalityVariance("code-866", name: "name-440")
        item.status = Imaging.TieredModalityVarianceStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.TieredModalityVarianceStatus.proposed) }
    }
}
