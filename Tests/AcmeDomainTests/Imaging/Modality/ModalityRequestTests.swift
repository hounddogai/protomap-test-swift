@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityRequestTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newModalityRequest("code-773", title: "title-526")
        #expect(item.status == Imaging.ModalityRequestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Imaging.newModalityRequest("code-773", title: "title-526")
        try item.moveTo(Imaging.ModalityRequestStatus.withdrawn)
        #expect(item.status == Imaging.ModalityRequestStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newModalityRequest("code-773", title: "title-526")
        item.status = Imaging.ModalityRequestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityRequestStatus.proposed) }
    }
}
