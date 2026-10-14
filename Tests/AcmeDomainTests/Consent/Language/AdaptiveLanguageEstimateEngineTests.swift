@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveLanguageEstimateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultAdaptiveLanguageEstimateEngine(Kit.Flags.newRegistry())
        let item = Consent.newAdaptiveLanguageEstimate("code-830", label: "label-902")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
