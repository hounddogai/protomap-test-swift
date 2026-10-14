@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackPrioritySlotTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newFallbackPrioritySlot("code-691", title: "title-109")
        #expect(item.status == Imaging.FallbackPrioritySlotStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Imaging.newFallbackPrioritySlot("code-691", title: "title-109")
        try item.moveTo(Imaging.FallbackPrioritySlotStatus.expired)
        #expect(item.status == Imaging.FallbackPrioritySlotStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newFallbackPrioritySlot("code-691", title: "title-109")
        item.status = Imaging.FallbackPrioritySlotStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.FallbackPrioritySlotStatus.requested) }
    }
}
