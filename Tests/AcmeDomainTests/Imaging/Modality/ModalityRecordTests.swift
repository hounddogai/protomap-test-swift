@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityRecordTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newModalityRecord("code-786", label: "label-835")
        #expect(item.status == Imaging.ModalityRecordStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Imaging.newModalityRecord("code-786", label: "label-835")
        try item.moveTo(Imaging.ModalityRecordStatus.warming)
        #expect(item.status == Imaging.ModalityRecordStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newModalityRecord("code-786", label: "label-835")
        item.status = Imaging.ModalityRecordStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityRecordStatus.idle) }
    }
}
