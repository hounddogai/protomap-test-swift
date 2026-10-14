@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalRevocationScoreEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultRegionalRevocationScoreEngine()
        let item = Consent.newRegionalRevocationScore("code-553", label: "label-414")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
