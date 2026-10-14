@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalAlertForecastTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newRegionalAlertForecast("code-705", name: "name-801")
        #expect(item.status == ClinicalOps.RegionalAlertForecastStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = ClinicalOps.newRegionalAlertForecast("code-705", name: "name-801")
        try item.moveTo(ClinicalOps.RegionalAlertForecastStatus.stopped)
        #expect(item.status == ClinicalOps.RegionalAlertForecastStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newRegionalAlertForecast("code-705", name: "name-801")
        item.status = ClinicalOps.RegionalAlertForecastStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RegionalAlertForecastStatus.idle) }
    }
}
