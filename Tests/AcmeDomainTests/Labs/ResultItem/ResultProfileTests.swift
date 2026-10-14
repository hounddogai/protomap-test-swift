@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultProfileTests {
    @Test func startsInOpen() throws {
        let item = Labs.newResultProfile("code-583", label: "label-274")
        #expect(item.status == Labs.ResultProfileStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Labs.newResultProfile("code-583", label: "label-274")
        try item.moveTo(Labs.ResultProfileStatus.inReview)
        #expect(item.status == Labs.ResultProfileStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newResultProfile("code-583", label: "label-274")
        item.status = Labs.ResultProfileStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultProfileStatus.`open`) }
    }
}
