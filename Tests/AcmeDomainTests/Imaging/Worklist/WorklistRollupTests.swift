@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistRollupTests {
    @Test func startsInNew() throws {
        let item = Imaging.newWorklistRollup("code-384", title: "title-367")
        #expect(item.status == Imaging.WorklistRollupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Imaging.newWorklistRollup("code-384", title: "title-367")
        try item.moveTo(Imaging.WorklistRollupStatus.done)
        #expect(item.status == Imaging.WorklistRollupStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newWorklistRollup("code-384", title: "title-367")
        item.status = Imaging.WorklistRollupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WorklistRollupStatus.new) }
    }
}
