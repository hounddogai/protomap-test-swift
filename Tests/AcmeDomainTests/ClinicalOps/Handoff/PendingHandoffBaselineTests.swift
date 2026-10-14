@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingHandoffBaselineTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newPendingHandoffBaseline("code-381", title: "title-847")
        #expect(item.status == ClinicalOps.PendingHandoffBaselineStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = ClinicalOps.newPendingHandoffBaseline("code-381", title: "title-847")
        try item.moveTo(ClinicalOps.PendingHandoffBaselineStatus.active)
        #expect(item.status == ClinicalOps.PendingHandoffBaselineStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newPendingHandoffBaseline("code-381", title: "title-847")
        item.status = ClinicalOps.PendingHandoffBaselineStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PendingHandoffBaselineStatus.draft) }
    }
}
