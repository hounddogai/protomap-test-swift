@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultWitnessPreferenceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultDefaultWitnessPreferenceEngine(Kit.Flags.newRegistry())
        let item = Consent.newDefaultWitnessPreference("code-912", name: "name-185")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
