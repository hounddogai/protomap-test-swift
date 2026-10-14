@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultPreferenceTests {
    @Test func startsInOpen() throws {
        let item = Labs.newResultPreference("code-300", title: "title-206")
        #expect(item.status == Labs.ResultPreferenceStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Labs.newResultPreference("code-300", title: "title-206")
        try item.moveTo(Labs.ResultPreferenceStatus.inReview)
        #expect(item.status == Labs.ResultPreferenceStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newResultPreference("code-300", title: "title-206")
        item.status = Labs.ResultPreferenceStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultPreferenceStatus.`open`) }
    }
}
