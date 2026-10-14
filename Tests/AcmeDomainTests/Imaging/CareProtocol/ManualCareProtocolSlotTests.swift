@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualCareProtocolSlotTests {
    @Test func startsInNew() throws {
        let item = Imaging.newManualCareProtocolSlot("code-646", label: "label-866")
        #expect(item.status == Imaging.ManualCareProtocolSlotStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Imaging.newManualCareProtocolSlot("code-646", label: "label-866")
        try item.moveTo(Imaging.ManualCareProtocolSlotStatus.running)
        #expect(item.status == Imaging.ManualCareProtocolSlotStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newManualCareProtocolSlot("code-646", label: "label-866")
        item.status = Imaging.ManualCareProtocolSlotStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ManualCareProtocolSlotStatus.new) }
    }
}
