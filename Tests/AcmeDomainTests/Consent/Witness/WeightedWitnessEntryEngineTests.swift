@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedWitnessEntryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultWeightedWitnessEntryEngine()
        let item = Consent.newWeightedWitnessEntry("code-964", name: "name-182")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
