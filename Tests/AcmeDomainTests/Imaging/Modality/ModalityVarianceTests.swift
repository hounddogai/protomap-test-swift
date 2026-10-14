@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityVarianceTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newModalityVariance("code-987", label: "label-414")
        #expect(item.status == Imaging.ModalityVarianceStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Imaging.newModalityVariance("code-987", label: "label-414")
        try item.moveTo(Imaging.ModalityVarianceStatus.resolved)
        #expect(item.status == Imaging.ModalityVarianceStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newModalityVariance("code-987", label: "label-414")
        item.status = Imaging.ModalityVarianceStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityVarianceStatus.`open`) }
    }
}
