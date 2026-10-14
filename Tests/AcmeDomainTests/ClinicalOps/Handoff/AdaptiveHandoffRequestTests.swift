@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveHandoffRequestTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newAdaptiveHandoffRequest("code-960", label: "label-904")
        #expect(item.status == ClinicalOps.AdaptiveHandoffRequestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = ClinicalOps.newAdaptiveHandoffRequest("code-960", label: "label-904")
        try item.moveTo(ClinicalOps.AdaptiveHandoffRequestStatus.reopened)
        #expect(item.status == ClinicalOps.AdaptiveHandoffRequestStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newAdaptiveHandoffRequest("code-960", label: "label-904")
        item.status = ClinicalOps.AdaptiveHandoffRequestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AdaptiveHandoffRequestStatus.`open`) }
    }
}
