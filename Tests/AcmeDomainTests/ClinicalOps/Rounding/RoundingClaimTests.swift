@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingClaimTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newRoundingClaim("code-540", name: "name-318")
        #expect(item.status == ClinicalOps.RoundingClaimStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = ClinicalOps.newRoundingClaim("code-540", name: "name-318")
        try item.moveTo(ClinicalOps.RoundingClaimStatus.reopened)
        #expect(item.status == ClinicalOps.RoundingClaimStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newRoundingClaim("code-540", name: "name-318")
        item.status = ClinicalOps.RoundingClaimStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingClaimStatus.`open`) }
    }
}
