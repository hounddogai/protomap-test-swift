@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessForecastTests {
    @Test func startsInIdle() throws {
        let item = Consent.newWitnessForecast("code-505", label: "label-2")
        #expect(item.status == Consent.WitnessForecastStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Consent.newWitnessForecast("code-505", label: "label-2")
        try item.moveTo(Consent.WitnessForecastStatus.warming)
        #expect(item.status == Consent.WitnessForecastStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newWitnessForecast("code-505", label: "label-2")
        item.status = Consent.WitnessForecastStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessForecastStatus.idle) }
    }
}
