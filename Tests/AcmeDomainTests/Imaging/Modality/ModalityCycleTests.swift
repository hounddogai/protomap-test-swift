@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityCycleTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newModalityCycle("code-42", label: "label-110")
        #expect(item.status == Imaging.ModalityCycleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Imaging.newModalityCycle("code-42", label: "label-110")
        try item.moveTo(Imaging.ModalityCycleStatus.retired)
        #expect(item.status == Imaging.ModalityCycleStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newModalityCycle("code-42", label: "label-110")
        item.status = Imaging.ModalityCycleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityCycleStatus.created) }
    }
}
