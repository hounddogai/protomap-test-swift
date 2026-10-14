@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsStrictResultClaimTests {
    @Test func startsInOpen() throws {
        let item = Labs.newStrictResultClaim("code-682", name: "name-71")
        #expect(item.status == Labs.StrictResultClaimStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Labs.newStrictResultClaim("code-682", name: "name-71")
        try item.moveTo(Labs.StrictResultClaimStatus.inReview)
        #expect(item.status == Labs.StrictResultClaimStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newStrictResultClaim("code-682", name: "name-71")
        item.status = Labs.StrictResultClaimStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.StrictResultClaimStatus.`open`) }
    }
}
