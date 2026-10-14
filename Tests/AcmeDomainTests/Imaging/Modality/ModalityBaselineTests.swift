@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityBaselineTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newModalityBaseline("code-408", label: "label-517")
        #expect(item.status == Imaging.ModalityBaselineStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Imaging.newModalityBaseline("code-408", label: "label-517")
        try item.moveTo(Imaging.ModalityBaselineStatus.revoked)
        #expect(item.status == Imaging.ModalityBaselineStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newModalityBaseline("code-408", label: "label-517")
        item.status = Imaging.ModalityBaselineStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityBaselineStatus.requested) }
    }
}
