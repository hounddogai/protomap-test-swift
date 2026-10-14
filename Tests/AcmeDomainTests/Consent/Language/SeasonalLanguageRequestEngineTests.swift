@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalLanguageRequestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultSeasonalLanguageRequestEngine(Kit.Flags.newRegistry())
        let item = Consent.newSeasonalLanguageRequest("code-28", name: "name-248")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
