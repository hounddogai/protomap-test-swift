@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictReadSlotTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newStrictReadSlot("code-82", title: "title-891")
        #expect(item.status == Imaging.StrictReadSlotStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Imaging.newStrictReadSlot("code-82", title: "title-891")
        try item.moveTo(Imaging.StrictReadSlotStatus.cancelled)
        #expect(item.status == Imaging.StrictReadSlotStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newStrictReadSlot("code-82", title: "title-891")
        item.status = Imaging.StrictReadSlotStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StrictReadSlotStatus.planned) }
    }
}
