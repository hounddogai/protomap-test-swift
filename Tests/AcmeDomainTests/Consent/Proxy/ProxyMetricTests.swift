@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyMetricTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newProxyMetric("code-768", name: "name-985")
        #expect(item.status == Consent.ProxyMetricStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Consent.newProxyMetric("code-768", name: "name-985")
        try item.moveTo(Consent.ProxyMetricStatus.completed)
        #expect(item.status == Consent.ProxyMetricStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newProxyMetric("code-768", name: "name-985")
        item.status = Consent.ProxyMetricStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyMetricStatus.planned) }
    }
}
