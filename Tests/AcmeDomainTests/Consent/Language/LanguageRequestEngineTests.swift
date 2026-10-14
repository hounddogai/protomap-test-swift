@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageRequestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultLanguageRequestEngine(Kit.Flags.newRegistry())
        let item = Consent.newLanguageRequest("code-115", title: "title-617")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
