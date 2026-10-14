@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalDisclosureBaselineEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultGlobalDisclosureBaselineEngine(Kit.Flags.newRegistry())
        let item = Consent.newGlobalDisclosureBaseline("code-615", name: "name-426")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
