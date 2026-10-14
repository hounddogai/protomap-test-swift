@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryAccessionClaimTests {
    @Test func startsInNew() throws {
        let item = Labs.newPrimaryAccessionClaim("code-884", name: "name-50")
        #expect(item.status == Labs.PrimaryAccessionClaimStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Labs.newPrimaryAccessionClaim("code-884", name: "name-50")
        try item.moveTo(Labs.PrimaryAccessionClaimStatus.queued)
        #expect(item.status == Labs.PrimaryAccessionClaimStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newPrimaryAccessionClaim("code-884", name: "name-50")
        item.status = Labs.PrimaryAccessionClaimStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PrimaryAccessionClaimStatus.new) }
    }
}
