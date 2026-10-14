@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingModalityClaimTests {
    @Test func startsInNew() throws {
        let item = Imaging.newRollingModalityClaim("code-414", name: "name-448")
        #expect(item.status == Imaging.RollingModalityClaimStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Imaging.newRollingModalityClaim("code-414", name: "name-448")
        try item.moveTo(Imaging.RollingModalityClaimStatus.queued)
        #expect(item.status == Imaging.RollingModalityClaimStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newRollingModalityClaim("code-414", name: "name-448")
        item.status = Imaging.RollingModalityClaimStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.RollingModalityClaimStatus.new) }
    }
}
