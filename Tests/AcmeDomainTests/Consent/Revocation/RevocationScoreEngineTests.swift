@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationScoreEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultRevocationScoreEngine(Kit.Flags.newRegistry())
        let item = Consent.newRevocationScore("code-345", label: "label-42")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
