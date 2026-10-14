@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryStudyBaselineTests {
    @Test func startsInNew() throws {
        let item = Imaging.newPrimaryStudyBaseline("code-323", label: "label-84")
        #expect(item.status == Imaging.PrimaryStudyBaselineStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Imaging.newPrimaryStudyBaseline("code-323", label: "label-84")
        try item.moveTo(Imaging.PrimaryStudyBaselineStatus.queued)
        #expect(item.status == Imaging.PrimaryStudyBaselineStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newPrimaryStudyBaseline("code-323", label: "label-84")
        item.status = Imaging.PrimaryStudyBaselineStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PrimaryStudyBaselineStatus.new) }
    }
}
