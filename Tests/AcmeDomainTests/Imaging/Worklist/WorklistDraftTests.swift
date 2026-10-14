@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistDraftTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newWorklistDraft("code-801", name: "name-271")
        #expect(item.status == Imaging.WorklistDraftStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Imaging.newWorklistDraft("code-801", name: "name-271")
        try item.moveTo(Imaging.WorklistDraftStatus.rejected)
        #expect(item.status == Imaging.WorklistDraftStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newWorklistDraft("code-801", name: "name-271")
        item.status = Imaging.WorklistDraftStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.WorklistDraftStatus.proposed) }
    }
}
