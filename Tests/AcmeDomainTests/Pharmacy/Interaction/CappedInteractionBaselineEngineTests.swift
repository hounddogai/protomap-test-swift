@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedInteractionBaselineEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultCappedInteractionBaselineEngine()
        let item = Pharmacy.newCappedInteractionBaseline("code-569", title: "title-444")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
