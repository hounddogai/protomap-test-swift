@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalOrderSetNoticeTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newSeasonalOrderSetNotice("code-891", label: "label-44")
        #expect(item.status == ClinicalOps.SeasonalOrderSetNoticeStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = ClinicalOps.newSeasonalOrderSetNotice("code-891", label: "label-44")
        try item.moveTo(ClinicalOps.SeasonalOrderSetNoticeStatus.running)
        #expect(item.status == ClinicalOps.SeasonalOrderSetNoticeStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newSeasonalOrderSetNotice("code-891", label: "label-44")
        item.status = ClinicalOps.SeasonalOrderSetNoticeStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.SeasonalOrderSetNoticeStatus.new) }
    }
}
