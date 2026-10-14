@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalStudyDigestTests {
    @Test func startsInNew() throws {
        let item = Imaging.newSeasonalStudyDigest("code-121", label: "label-770")
        #expect(item.status == Imaging.SeasonalStudyDigestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Imaging.newSeasonalStudyDigest("code-121", label: "label-770")
        try item.moveTo(Imaging.SeasonalStudyDigestStatus.done)
        #expect(item.status == Imaging.SeasonalStudyDigestStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newSeasonalStudyDigest("code-121", label: "label-770")
        item.status = Imaging.SeasonalStudyDigestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.SeasonalStudyDigestStatus.new) }
    }
}
