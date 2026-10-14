@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLegacyRevocationManifestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultLegacyRevocationManifestEngine()
        let item = Consent.newLegacyRevocationManifest("code-35", name: "name-3")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
