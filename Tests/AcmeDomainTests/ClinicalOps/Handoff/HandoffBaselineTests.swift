@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffBaselineTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newHandoffBaseline("code-156", title: "title-144")
        #expect(item.status == ClinicalOps.HandoffBaselineStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = ClinicalOps.newHandoffBaseline("code-156", title: "title-144")
        try item.moveTo(ClinicalOps.HandoffBaselineStatus.approved)
        #expect(item.status == ClinicalOps.HandoffBaselineStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newHandoffBaseline("code-156", title: "title-144")
        item.status = ClinicalOps.HandoffBaselineStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.HandoffBaselineStatus.proposed) }
    }
}
