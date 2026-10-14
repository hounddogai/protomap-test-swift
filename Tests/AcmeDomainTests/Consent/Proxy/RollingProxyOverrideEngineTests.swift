@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingProxyOverrideEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultRollingProxyOverrideEngine(Kit.Flags.newRegistry())
        let item = Consent.newRollingProxyOverride("code-137", name: "name-500")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
