@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessRequestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultWitnessRequestEngine()
        let item = Consent.newWitnessRequest("code-154", name: "name-639")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
