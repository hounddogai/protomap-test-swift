@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeBaselineTests {
    @Test func startsInOpen() throws {
        let item = Labs.newReferenceRangeBaseline("code-310", name: "name-660")
        #expect(item.status == Labs.ReferenceRangeBaselineStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Labs.newReferenceRangeBaseline("code-310", name: "name-660")
        try item.moveTo(Labs.ReferenceRangeBaselineStatus.inReview)
        #expect(item.status == Labs.ReferenceRangeBaselineStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newReferenceRangeBaseline("code-310", name: "name-660")
        item.status = Labs.ReferenceRangeBaselineStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeBaselineStatus.`open`) }
    }
}
