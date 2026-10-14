@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedDisclosureCycleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultBatchedDisclosureCycleEngine(Kit.Flags.newRegistry())
        let item = Consent.newBatchedDisclosureCycle("code-416", name: "name-318")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
