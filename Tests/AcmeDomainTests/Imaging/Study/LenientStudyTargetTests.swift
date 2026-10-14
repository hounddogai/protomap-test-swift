@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientStudyTargetTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newLenientStudyTarget("code-835", name: "name-888")
        #expect(item.status == Imaging.LenientStudyTargetStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Imaging.newLenientStudyTarget("code-835", name: "name-888")
        try item.moveTo(Imaging.LenientStudyTargetStatus.inProgress)
        #expect(item.status == Imaging.LenientStudyTargetStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newLenientStudyTarget("code-835", name: "name-888")
        item.status = Imaging.LenientStudyTargetStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.LenientStudyTargetStatus.planned) }
    }
}
