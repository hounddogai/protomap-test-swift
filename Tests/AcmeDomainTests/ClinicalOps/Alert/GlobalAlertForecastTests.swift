@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalAlertForecastTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newGlobalAlertForecast("code-130", label: "label-595")
        #expect(item.status == ClinicalOps.GlobalAlertForecastStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = ClinicalOps.newGlobalAlertForecast("code-130", label: "label-595")
        try item.moveTo(ClinicalOps.GlobalAlertForecastStatus.validated)
        #expect(item.status == ClinicalOps.GlobalAlertForecastStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newGlobalAlertForecast("code-130", label: "label-595")
        item.status = ClinicalOps.GlobalAlertForecastStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.GlobalAlertForecastStatus.created) }
    }
}
