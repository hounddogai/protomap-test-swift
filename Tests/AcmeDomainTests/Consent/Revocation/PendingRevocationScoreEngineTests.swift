@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingRevocationScoreEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultPendingRevocationScoreEngine()
        let item = Consent.newPendingRevocationScore("code-366", label: "label-151")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
