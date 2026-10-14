@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertForecastTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newAlertForecast("code-584", title: "title-622")
        #expect(item.status == ClinicalOps.AlertForecastStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = ClinicalOps.newAlertForecast("code-584", title: "title-622")
        try item.moveTo(ClinicalOps.AlertForecastStatus.granted)
        #expect(item.status == ClinicalOps.AlertForecastStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newAlertForecast("code-584", title: "title-622")
        item.status = ClinicalOps.AlertForecastStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertForecastStatus.requested) }
    }
}
