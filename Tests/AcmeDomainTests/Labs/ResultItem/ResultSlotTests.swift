@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultSlotTests {
    @Test func startsInDraft() throws {
        let item = Labs.newResultSlot("code-959", label: "label-858")
        #expect(item.status == Labs.ResultSlotStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Labs.newResultSlot("code-959", label: "label-858")
        try item.moveTo(Labs.ResultSlotStatus.pending)
        #expect(item.status == Labs.ResultSlotStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newResultSlot("code-959", label: "label-858")
        item.status = Labs.ResultSlotStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultSlotStatus.draft) }
    }
}
