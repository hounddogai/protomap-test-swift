@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictProxyTargetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultStrictProxyTargetEngine(Kit.Flags.newRegistry())
        let item = Consent.newStrictProxyTarget("code-647", label: "label-82")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
