@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingCensusForecastTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newRollingCensusForecast("code-555", label: "label-986")
        #expect(item.status == BedManagement.RollingCensusForecastStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = BedManagement.newRollingCensusForecast("code-555", label: "label-986")
        try item.moveTo(BedManagement.RollingCensusForecastStatus.published)
        #expect(item.status == BedManagement.RollingCensusForecastStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newRollingCensusForecast("code-555", label: "label-986")
        item.status = BedManagement.RollingCensusForecastStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.RollingCensusForecastStatus.created) }
    }
}
