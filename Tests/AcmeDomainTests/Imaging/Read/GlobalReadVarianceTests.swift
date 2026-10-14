@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalReadVarianceTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newGlobalReadVariance("code-389", label: "label-487")
        #expect(item.status == Imaging.GlobalReadVarianceStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Imaging.newGlobalReadVariance("code-389", label: "label-487")
        try item.moveTo(Imaging.GlobalReadVarianceStatus.scheduled)
        #expect(item.status == Imaging.GlobalReadVarianceStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newGlobalReadVariance("code-389", label: "label-487")
        item.status = Imaging.GlobalReadVarianceStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.GlobalReadVarianceStatus.planned) }
    }
}
