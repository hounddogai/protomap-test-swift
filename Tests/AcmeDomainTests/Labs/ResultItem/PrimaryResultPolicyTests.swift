@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryResultPolicyTests {
    @Test func startsInOpen() throws {
        let item = Labs.newPrimaryResultPolicy("code-997", title: "title-232")
        #expect(item.status == Labs.PrimaryResultPolicyStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Labs.newPrimaryResultPolicy("code-997", title: "title-232")
        try item.moveTo(Labs.PrimaryResultPolicyStatus.inReview)
        #expect(item.status == Labs.PrimaryResultPolicyStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newPrimaryResultPolicy("code-997", title: "title-232")
        item.status = Labs.PrimaryResultPolicyStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PrimaryResultPolicyStatus.`open`) }
    }
}
