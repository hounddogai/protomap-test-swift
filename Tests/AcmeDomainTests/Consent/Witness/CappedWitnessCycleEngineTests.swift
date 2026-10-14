@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedWitnessCycleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultCappedWitnessCycleEngine()
        let item = Consent.newCappedWitnessCycle("code-697", title: "title-74")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
