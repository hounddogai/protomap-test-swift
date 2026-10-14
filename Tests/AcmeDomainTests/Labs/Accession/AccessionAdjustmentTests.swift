@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionAdjustmentTests {
    @Test func startsInDraft() throws {
        let item = Labs.newAccessionAdjustment("code-616", title: "title-747")
        #expect(item.status == Labs.AccessionAdjustmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Labs.newAccessionAdjustment("code-616", title: "title-747")
        try item.moveTo(Labs.AccessionAdjustmentStatus.pending)
        #expect(item.status == Labs.AccessionAdjustmentStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newAccessionAdjustment("code-616", title: "title-747")
        item.status = Labs.AccessionAdjustmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AccessionAdjustmentStatus.draft) }
    }
}
