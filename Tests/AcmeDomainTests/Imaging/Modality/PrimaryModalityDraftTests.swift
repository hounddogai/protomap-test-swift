@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryModalityDraftTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newPrimaryModalityDraft("code-408", label: "label-38")
        #expect(item.status == Imaging.PrimaryModalityDraftStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Imaging.newPrimaryModalityDraft("code-408", label: "label-38")
        try item.moveTo(Imaging.PrimaryModalityDraftStatus.archived)
        #expect(item.status == Imaging.PrimaryModalityDraftStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newPrimaryModalityDraft("code-408", label: "label-38")
        item.status = Imaging.PrimaryModalityDraftStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PrimaryModalityDraftStatus.`open`) }
    }
}
