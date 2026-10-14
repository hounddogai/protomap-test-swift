@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackLanguagePlanEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultFallbackLanguagePlanEngine(Kit.Flags.newRegistry())
        let item = Consent.newFallbackLanguagePlan("code-466", title: "title-232")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
