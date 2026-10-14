@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalReadExceptionTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newSeasonalReadException("code-328", label: "label-435")
        #expect(item.status == Imaging.SeasonalReadExceptionStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newSeasonalReadException("code-328", label: "label-435")
        try item.moveTo(Imaging.SeasonalReadExceptionStatus.validated)
        #expect(item.status == Imaging.SeasonalReadExceptionStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newSeasonalReadException("code-328", label: "label-435")
        item.status = Imaging.SeasonalReadExceptionStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.SeasonalReadExceptionStatus.created) }
    }
}
