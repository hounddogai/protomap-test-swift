@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalOrderSetWindowTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newSeasonalOrderSetWindow("code-955", name: "name-530")
        #expect(item.status == ClinicalOps.SeasonalOrderSetWindowStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = ClinicalOps.newSeasonalOrderSetWindow("code-955", name: "name-530")
        try item.moveTo(ClinicalOps.SeasonalOrderSetWindowStatus.closed)
        #expect(item.status == ClinicalOps.SeasonalOrderSetWindowStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newSeasonalOrderSetWindow("code-955", name: "name-530")
        item.status = ClinicalOps.SeasonalOrderSetWindowStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.SeasonalOrderSetWindowStatus.draft) }
    }
}
