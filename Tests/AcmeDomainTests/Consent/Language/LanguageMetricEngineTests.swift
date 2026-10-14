@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageMetricEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultLanguageMetricEngine(Kit.Flags.newRegistry())
        let item = Consent.newLanguageMetric("code-347", name: "name-345")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
