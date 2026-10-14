@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageTierEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultLanguageTierEngine()
        let item = Consent.newLanguageTier("code-475", title: "title-949")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
