@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictReadBaselineTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newStrictReadBaseline("code-683", name: "name-611")
        #expect(item.status == Imaging.StrictReadBaselineStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Imaging.newStrictReadBaseline("code-683", name: "name-611")
        try item.moveTo(Imaging.StrictReadBaselineStatus.closed)
        #expect(item.status == Imaging.StrictReadBaselineStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newStrictReadBaseline("code-683", name: "name-611")
        item.status = Imaging.StrictReadBaselineStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StrictReadBaselineStatus.draft) }
    }
}
