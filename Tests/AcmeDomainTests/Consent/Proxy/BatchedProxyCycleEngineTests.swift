@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedProxyCycleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultBatchedProxyCycleEngine()
        let item = Consent.newBatchedProxyCycle("code-306", title: "title-473")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
