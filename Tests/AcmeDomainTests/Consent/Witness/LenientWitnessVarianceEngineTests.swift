@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientWitnessVarianceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultLenientWitnessVarianceEngine()
        let item = Consent.newLenientWitnessVariance("code-609", name: "name-107")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
