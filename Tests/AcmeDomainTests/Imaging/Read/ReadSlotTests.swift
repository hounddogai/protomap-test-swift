@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadSlotTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newReadSlot("code-190", label: "label-379")
        #expect(item.status == Imaging.ReadSlotStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Imaging.newReadSlot("code-190", label: "label-379")
        try item.moveTo(Imaging.ReadSlotStatus.warming)
        #expect(item.status == Imaging.ReadSlotStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newReadSlot("code-190", label: "label-379")
        item.status = Imaging.ReadSlotStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ReadSlotStatus.idle) }
    }
}
