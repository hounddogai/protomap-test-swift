@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultRevocationWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultDefaultRevocationWindowEngine()
        let item = Consent.newDefaultRevocationWindow("code-327", label: "label-189")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
