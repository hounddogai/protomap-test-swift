@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingAlertForecastTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newRollingAlertForecast("code-217", label: "label-55")
        #expect(item.status == ClinicalOps.RollingAlertForecastStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = ClinicalOps.newRollingAlertForecast("code-217", label: "label-55")
        try item.moveTo(ClinicalOps.RollingAlertForecastStatus.active)
        #expect(item.status == ClinicalOps.RollingAlertForecastStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newRollingAlertForecast("code-217", label: "label-55")
        item.status = ClinicalOps.RollingAlertForecastStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RollingAlertForecastStatus.draft) }
    }
}
