@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingRevocationManifestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultRollingRevocationManifestEngine(Kit.Flags.newRegistry())
        let item = Consent.newRollingRevocationManifest("code-919", name: "name-342")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
