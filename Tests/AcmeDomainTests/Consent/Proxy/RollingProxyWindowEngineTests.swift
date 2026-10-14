@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingProxyWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultRollingProxyWindowEngine()
        let item = Consent.newRollingProxyWindow("code-781", name: "name-112")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
