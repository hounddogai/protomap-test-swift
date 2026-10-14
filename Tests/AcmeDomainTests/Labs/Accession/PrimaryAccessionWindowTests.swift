@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryAccessionWindowTests {
    @Test func startsInOpen() throws {
        let item = Labs.newPrimaryAccessionWindow("code-483", label: "label-661")
        #expect(item.status == Labs.PrimaryAccessionWindowStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Labs.newPrimaryAccessionWindow("code-483", label: "label-661")
        try item.moveTo(Labs.PrimaryAccessionWindowStatus.inReview)
        #expect(item.status == Labs.PrimaryAccessionWindowStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newPrimaryAccessionWindow("code-483", label: "label-661")
        item.status = Labs.PrimaryAccessionWindowStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PrimaryAccessionWindowStatus.`open`) }
    }
}
