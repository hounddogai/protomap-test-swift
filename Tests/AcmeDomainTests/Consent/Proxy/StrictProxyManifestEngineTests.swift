@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictProxyManifestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultStrictProxyManifestEngine(Kit.Flags.newRegistry())
        let item = Consent.newStrictProxyManifest("code-756", label: "label-179")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
