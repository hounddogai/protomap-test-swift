@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalDisclosureForecastTests {
    @Test func startsInProposed() throws {
        let item = Consent.newGlobalDisclosureForecast("code-466", label: "label-800")
        #expect(item.status == Consent.GlobalDisclosureForecastStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Consent.newGlobalDisclosureForecast("code-466", label: "label-800")
        try item.moveTo(Consent.GlobalDisclosureForecastStatus.approved)
        #expect(item.status == Consent.GlobalDisclosureForecastStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newGlobalDisclosureForecast("code-466", label: "label-800")
        item.status = Consent.GlobalDisclosureForecastStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.GlobalDisclosureForecastStatus.proposed) }
    }
}
