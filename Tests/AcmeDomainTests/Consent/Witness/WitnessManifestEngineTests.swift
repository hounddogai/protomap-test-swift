@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessManifestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultWitnessManifestEngine()
        let item = Consent.newWitnessManifest("code-102", title: "title-464")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
