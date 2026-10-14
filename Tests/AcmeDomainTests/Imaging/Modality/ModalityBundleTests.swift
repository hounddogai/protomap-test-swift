@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityBundleTests {
    @Test func startsInProposed() throws {
        let item = Imaging.newModalityBundle("code-797", label: "label-414")
        #expect(item.status == Imaging.ModalityBundleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Imaging.newModalityBundle("code-797", label: "label-414")
        try item.moveTo(Imaging.ModalityBundleStatus.approved)
        #expect(item.status == Imaging.ModalityBundleStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Imaging.newModalityBundle("code-797", label: "label-414")
        item.status = Imaging.ModalityBundleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityBundleStatus.proposed) }
    }
}
