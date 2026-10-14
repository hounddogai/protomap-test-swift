@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguagePlanEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultLanguagePlanEngine(Kit.Flags.newRegistry())
        let item = Consent.newLanguagePlan("code-357", name: "name-71")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
