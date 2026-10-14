@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingStudyBaselineTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newPendingStudyBaseline("code-661", title: "title-546")
        #expect(item.status == Imaging.PendingStudyBaselineStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Imaging.newPendingStudyBaseline("code-661", title: "title-546")
        try item.moveTo(Imaging.PendingStudyBaselineStatus.suspended)
        #expect(item.status == Imaging.PendingStudyBaselineStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newPendingStudyBaseline("code-661", title: "title-546")
        item.status = Imaging.PendingStudyBaselineStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PendingStudyBaselineStatus.draft) }
    }
}
