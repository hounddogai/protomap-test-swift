@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientModalityScoreTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newLenientModalityScore("code-900", title: "title-390")
        #expect(item.status == Imaging.LenientModalityScoreStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Imaging.newLenientModalityScore("code-900", title: "title-390")
        try item.moveTo(Imaging.LenientModalityScoreStatus.completed)
        #expect(item.status == Imaging.LenientModalityScoreStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newLenientModalityScore("code-900", title: "title-390")
        item.status = Imaging.LenientModalityScoreStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.LenientModalityScoreStatus.planned) }
    }
}
