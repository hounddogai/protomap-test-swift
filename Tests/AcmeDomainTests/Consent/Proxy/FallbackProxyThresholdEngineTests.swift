@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackProxyThresholdEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultFallbackProxyThresholdEngine()
        let item = Consent.newFallbackProxyThreshold("code-952", name: "name-883")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
