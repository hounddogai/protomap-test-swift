@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangePreferenceTests {
    @Test func startsInOpen() throws {
        let item = Labs.newReferenceRangePreference("code-481", title: "title-919")
        #expect(item.status == Labs.ReferenceRangePreferenceStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Labs.newReferenceRangePreference("code-481", title: "title-919")
        try item.moveTo(Labs.ReferenceRangePreferenceStatus.inReview)
        #expect(item.status == Labs.ReferenceRangePreferenceStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newReferenceRangePreference("code-481", title: "title-919")
        item.status = Labs.ReferenceRangePreferenceStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangePreferenceStatus.`open`) }
    }
}
