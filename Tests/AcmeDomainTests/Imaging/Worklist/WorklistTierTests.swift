@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistTierTests {
    @Test func startsInNew() throws {
        let item = Imaging.newWorklistTier("code-174", name: "name-379")
        #expect(item.status == Imaging.WorklistTierStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Imaging.newWorklistTier("code-174", name: "name-379")
        try item.moveTo(Imaging.WorklistTierStatus.queued)
        #expect(item.status == Imaging.WorklistTierStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newWorklistTier("code-174", name: "name-379")
        item.status = Imaging.WorklistTierStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WorklistTierStatus.new) }
    }
}
