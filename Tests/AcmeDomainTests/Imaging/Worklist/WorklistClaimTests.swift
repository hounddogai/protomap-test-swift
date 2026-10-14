@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistClaimTests {
    @Test func startsInNew() throws {
        let item = Imaging.newWorklistClaim("code-618", name: "name-527")
        #expect(item.status == Imaging.WorklistClaimStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Imaging.newWorklistClaim("code-618", name: "name-527")
        try item.moveTo(Imaging.WorklistClaimStatus.done)
        #expect(item.status == Imaging.WorklistClaimStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newWorklistClaim("code-618", name: "name-527")
        item.status = Imaging.WorklistClaimStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WorklistClaimStatus.new) }
    }
}
