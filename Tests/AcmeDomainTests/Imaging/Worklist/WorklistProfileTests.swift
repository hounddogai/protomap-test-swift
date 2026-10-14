@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistProfileTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newWorklistProfile("code-206", label: "label-894")
        #expect(item.status == Imaging.WorklistProfileStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Imaging.newWorklistProfile("code-206", label: "label-894")
        try item.moveTo(Imaging.WorklistProfileStatus.pending)
        #expect(item.status == Imaging.WorklistProfileStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newWorklistProfile("code-206", label: "label-894")
        item.status = Imaging.WorklistProfileStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WorklistProfileStatus.draft) }
    }
}
