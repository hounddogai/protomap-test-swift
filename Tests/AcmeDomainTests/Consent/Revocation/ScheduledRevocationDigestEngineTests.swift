@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledRevocationDigestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultScheduledRevocationDigestEngine(Kit.Flags.newRegistry())
        let item = Consent.newScheduledRevocationDigest("code-300", name: "name-170")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
