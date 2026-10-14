@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalOrderSetAgreementTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newSeasonalOrderSetAgreement("code-331", label: "label-897")
        #expect(item.status == ClinicalOps.SeasonalOrderSetAgreementStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = ClinicalOps.newSeasonalOrderSetAgreement("code-331", label: "label-897")
        try item.moveTo(ClinicalOps.SeasonalOrderSetAgreementStatus.queued)
        #expect(item.status == ClinicalOps.SeasonalOrderSetAgreementStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newSeasonalOrderSetAgreement("code-331", label: "label-897")
        item.status = ClinicalOps.SeasonalOrderSetAgreementStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.SeasonalOrderSetAgreementStatus.new) }
    }
}
