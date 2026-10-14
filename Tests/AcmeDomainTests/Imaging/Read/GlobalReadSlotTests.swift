@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalReadSlotTests {
    @Test func startsInNew() throws {
        let item = Imaging.newGlobalReadSlot("code-189", name: "name-254")
        #expect(item.status == Imaging.GlobalReadSlotStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Imaging.newGlobalReadSlot("code-189", name: "name-254")
        try item.moveTo(Imaging.GlobalReadSlotStatus.running)
        #expect(item.status == Imaging.GlobalReadSlotStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newGlobalReadSlot("code-189", name: "name-254")
        item.status = Imaging.GlobalReadSlotStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.GlobalReadSlotStatus.new) }
    }
}
