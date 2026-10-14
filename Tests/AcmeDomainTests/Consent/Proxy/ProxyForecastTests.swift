@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyForecastTests {
    @Test func startsInCreated() throws {
        let item = Consent.newProxyForecast("code-801", name: "name-980")
        #expect(item.status == Consent.ProxyForecastStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Consent.newProxyForecast("code-801", name: "name-980")
        try item.moveTo(Consent.ProxyForecastStatus.published)
        #expect(item.status == Consent.ProxyForecastStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newProxyForecast("code-801", name: "name-980")
        item.status = Consent.ProxyForecastStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyForecastStatus.created) }
    }
}
