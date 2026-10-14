@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingForecastTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newRoundingForecast("code-621", label: "label-421")
        #expect(item.status == ClinicalOps.RoundingForecastStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = ClinicalOps.newRoundingForecast("code-621", label: "label-421")
        try item.moveTo(ClinicalOps.RoundingForecastStatus.running)
        #expect(item.status == ClinicalOps.RoundingForecastStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newRoundingForecast("code-621", label: "label-421")
        item.status = ClinicalOps.RoundingForecastStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingForecastStatus.new) }
    }
}
