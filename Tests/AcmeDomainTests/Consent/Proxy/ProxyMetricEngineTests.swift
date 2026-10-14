@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyMetricEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultProxyMetricEngine(Kit.Flags.newRegistry())
        let item = Consent.newProxyMetric("code-768", name: "name-985")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
