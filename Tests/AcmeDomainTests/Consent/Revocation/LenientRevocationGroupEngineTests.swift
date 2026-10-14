@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientRevocationGroupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultLenientRevocationGroupEngine()
        let item = Consent.newLenientRevocationGroup("code-26", name: "name-862")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
