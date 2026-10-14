@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveWorklistDraftTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newAdaptiveWorklistDraft("code-777", name: "name-636")
        #expect(item.status == Imaging.AdaptiveWorklistDraftStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newAdaptiveWorklistDraft("code-777", name: "name-636")
        try item.moveTo(Imaging.AdaptiveWorklistDraftStatus.validated)
        #expect(item.status == Imaging.AdaptiveWorklistDraftStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newAdaptiveWorklistDraft("code-777", name: "name-636")
        item.status = Imaging.AdaptiveWorklistDraftStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.AdaptiveWorklistDraftStatus.created) }
    }
}
