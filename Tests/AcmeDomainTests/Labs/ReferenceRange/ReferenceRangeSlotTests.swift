@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeSlotTests {
    @Test func startsInDraft() throws {
        let item = Labs.newReferenceRangeSlot("code-932", label: "label-509")
        #expect(item.status == Labs.ReferenceRangeSlotStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Labs.newReferenceRangeSlot("code-932", label: "label-509")
        try item.moveTo(Labs.ReferenceRangeSlotStatus.suspended)
        #expect(item.status == Labs.ReferenceRangeSlotStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newReferenceRangeSlot("code-932", label: "label-509")
        item.status = Labs.ReferenceRangeSlotStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeSlotStatus.draft) }
    }
}
