@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedCourierDraftTests {
    @Test func startsInRequested() throws {
        let item = Labs.newWeightedCourierDraft("code-39", title: "title-842")
        #expect(item.status == Labs.WeightedCourierDraftStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Labs.newWeightedCourierDraft("code-39", title: "title-842")
        try item.moveTo(Labs.WeightedCourierDraftStatus.expired)
        #expect(item.status == Labs.WeightedCourierDraftStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newWeightedCourierDraft("code-39", title: "title-842")
        item.status = Labs.WeightedCourierDraftStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.WeightedCourierDraftStatus.requested) }
    }
}
