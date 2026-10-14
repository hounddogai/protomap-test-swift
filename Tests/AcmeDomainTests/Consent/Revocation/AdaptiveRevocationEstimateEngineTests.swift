@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveRevocationEstimateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultAdaptiveRevocationEstimateEngine(Kit.Flags.newRegistry())
        let item = Consent.newAdaptiveRevocationEstimate("code-855", title: "title-245")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
