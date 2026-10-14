@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualCensusForecastTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newManualCensusForecast("code-67", name: "name-533")
        #expect(item.status == BedManagement.ManualCensusForecastStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = BedManagement.newManualCensusForecast("code-67", name: "name-533")
        try item.moveTo(BedManagement.ManualCensusForecastStatus.draining)
        #expect(item.status == BedManagement.ManualCensusForecastStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newManualCensusForecast("code-67", name: "name-533")
        item.status = BedManagement.ManualCensusForecastStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ManualCensusForecastStatus.idle) }
    }
}
