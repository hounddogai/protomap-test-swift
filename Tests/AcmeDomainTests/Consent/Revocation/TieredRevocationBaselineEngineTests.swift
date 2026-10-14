@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredRevocationBaselineEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultTieredRevocationBaselineEngine()
        let item = Consent.newTieredRevocationBaseline("code-972", name: "name-87")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
