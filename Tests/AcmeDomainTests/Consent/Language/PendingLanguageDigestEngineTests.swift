@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingLanguageDigestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultPendingLanguageDigestEngine()
        let item = Consent.newPendingLanguageDigest("code-383", name: "name-28")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
