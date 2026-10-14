@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingDisclosureWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultPendingDisclosureWindowEngine()
        let item = Consent.newPendingDisclosureWindow("code-578", name: "name-613")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
