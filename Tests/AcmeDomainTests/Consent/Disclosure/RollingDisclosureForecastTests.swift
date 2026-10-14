@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingDisclosureForecastTests {
    @Test func startsInIdle() throws {
        let item = Consent.newRollingDisclosureForecast("code-895", title: "title-925")
        #expect(item.status == Consent.RollingDisclosureForecastStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Consent.newRollingDisclosureForecast("code-895", title: "title-925")
        try item.moveTo(Consent.RollingDisclosureForecastStatus.warming)
        #expect(item.status == Consent.RollingDisclosureForecastStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newRollingDisclosureForecast("code-895", title: "title-925")
        item.status = Consent.RollingDisclosureForecastStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RollingDisclosureForecastStatus.idle) }
    }
}
