@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedModalityDraftTests {
    @Test func startsInNew() throws {
        let item = Imaging.newCappedModalityDraft("code-299", label: "label-197")
        #expect(item.status == Imaging.CappedModalityDraftStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Imaging.newCappedModalityDraft("code-299", label: "label-197")
        try item.moveTo(Imaging.CappedModalityDraftStatus.queued)
        #expect(item.status == Imaging.CappedModalityDraftStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newCappedModalityDraft("code-299", label: "label-197")
        item.status = Imaging.CappedModalityDraftStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CappedModalityDraftStatus.new) }
    }
}
