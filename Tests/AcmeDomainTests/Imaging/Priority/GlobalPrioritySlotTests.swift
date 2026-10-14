@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalPrioritySlotTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newGlobalPrioritySlot("code-931", label: "label-71")
        #expect(item.status == Imaging.GlobalPrioritySlotStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Imaging.newGlobalPrioritySlot("code-931", label: "label-71")
        try item.moveTo(Imaging.GlobalPrioritySlotStatus.reopened)
        #expect(item.status == Imaging.GlobalPrioritySlotStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newGlobalPrioritySlot("code-931", label: "label-71")
        item.status = Imaging.GlobalPrioritySlotStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.GlobalPrioritySlotStatus.`open`) }
    }
}
