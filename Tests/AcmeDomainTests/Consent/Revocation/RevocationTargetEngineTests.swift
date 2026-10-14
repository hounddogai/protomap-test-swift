@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationTargetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultRevocationTargetEngine(Kit.Flags.newRegistry())
        let item = Consent.newRevocationTarget("code-860", title: "title-482")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
