@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalOrderSetTemplateTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newSeasonalOrderSetTemplate("code-171", label: "label-755")
        #expect(item.status == ClinicalOps.SeasonalOrderSetTemplateStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = ClinicalOps.newSeasonalOrderSetTemplate("code-171", label: "label-755")
        try item.moveTo(ClinicalOps.SeasonalOrderSetTemplateStatus.queued)
        #expect(item.status == ClinicalOps.SeasonalOrderSetTemplateStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newSeasonalOrderSetTemplate("code-171", label: "label-755")
        item.status = ClinicalOps.SeasonalOrderSetTemplateStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.SeasonalOrderSetTemplateStatus.new) }
    }
}
