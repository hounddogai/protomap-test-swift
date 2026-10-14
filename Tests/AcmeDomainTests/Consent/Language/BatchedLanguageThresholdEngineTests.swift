@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedLanguageThresholdEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultBatchedLanguageThresholdEngine(Kit.Flags.newRegistry())
        let item = Consent.newBatchedLanguageThreshold("code-603", label: "label-531")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
