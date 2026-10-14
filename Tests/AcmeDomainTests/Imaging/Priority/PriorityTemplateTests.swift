@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityTemplateTests {
    @Test func startsInDraft() throws {
        let item = Imaging.newPriorityTemplate("code-355", label: "label-553")
        #expect(item.status == Imaging.PriorityTemplateStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Imaging.newPriorityTemplate("code-355", label: "label-553")
        try item.moveTo(Imaging.PriorityTemplateStatus.pending)
        #expect(item.status == Imaging.PriorityTemplateStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Imaging.newPriorityTemplate("code-355", label: "label-553")
        item.status = Imaging.PriorityTemplateStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PriorityTemplateStatus.draft) }
    }
}
