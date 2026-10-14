@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultProxyWindowEngine(Kit.Flags.newRegistry())
        let item = Consent.newProxyWindow("code-264", label: "label-866")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
