@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyEstimateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultProxyEstimateEngine()
        let item = Consent.newProxyEstimate("code-808", label: "label-86")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
