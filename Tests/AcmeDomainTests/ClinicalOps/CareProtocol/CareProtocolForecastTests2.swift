@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolForecastTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newCareProtocolForecast("code-445", title: "title-754")
        #expect(item.status == ClinicalOps.CareProtocolForecastStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = ClinicalOps.newCareProtocolForecast("code-445", title: "title-754")
        try item.moveTo(ClinicalOps.CareProtocolForecastStatus.scheduled)
        #expect(item.status == ClinicalOps.CareProtocolForecastStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newCareProtocolForecast("code-445", title: "title-754")
        item.status = ClinicalOps.CareProtocolForecastStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolForecastStatus.planned) }
    }
}
