@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryTaskClaimTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newPrimaryTaskClaim("code-417", label: "label-517")
        #expect(item.status == ClinicalOps.PrimaryTaskClaimStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = ClinicalOps.newPrimaryTaskClaim("code-417", label: "label-517")
        try item.moveTo(ClinicalOps.PrimaryTaskClaimStatus.reopened)
        #expect(item.status == ClinicalOps.PrimaryTaskClaimStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newPrimaryTaskClaim("code-417", label: "label-517")
        item.status = ClinicalOps.PrimaryTaskClaimStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PrimaryTaskClaimStatus.`open`) }
    }
}
