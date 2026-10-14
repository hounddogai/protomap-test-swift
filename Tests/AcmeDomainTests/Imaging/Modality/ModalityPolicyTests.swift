@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityPolicyTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newModalityPolicy("code-630", name: "name-754")
        #expect(item.status == Imaging.ModalityPolicyStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Imaging.newModalityPolicy("code-630", name: "name-754")
        try item.moveTo(Imaging.ModalityPolicyStatus.withdrawn)
        #expect(item.status == Imaging.ModalityPolicyStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newModalityPolicy("code-630", name: "name-754")
        item.status = Imaging.ModalityPolicyStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityPolicyStatus.proposed) }
    }
}
