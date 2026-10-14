@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityClaimTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newModalityClaim("code-349", label: "label-827")
        #expect(item.status == Imaging.ModalityClaimStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Imaging.newModalityClaim("code-349", label: "label-827")
        try item.moveTo(Imaging.ModalityClaimStatus.cancelled)
        #expect(item.status == Imaging.ModalityClaimStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newModalityClaim("code-349", label: "label-827")
        item.status = Imaging.ModalityClaimStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityClaimStatus.planned) }
    }
}
