@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultProxyScoreEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultDefaultProxyScoreEngine(Kit.Flags.newRegistry())
        let item = Consent.newDefaultProxyScore("code-353", label: "label-203")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
