@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrioritySlotTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newPrioritySlot("code-422", title: "title-83")
        #expect(item.status == Imaging.PrioritySlotStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Imaging.newPrioritySlot("code-422", title: "title-83")
        try item.moveTo(Imaging.PrioritySlotStatus.inReview)
        #expect(item.status == Imaging.PrioritySlotStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newPrioritySlot("code-422", title: "title-83")
        item.status = Imaging.PrioritySlotStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PrioritySlotStatus.`open`) }
    }
}
