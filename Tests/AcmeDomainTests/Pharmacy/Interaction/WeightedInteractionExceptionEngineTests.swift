@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedInteractionExceptionEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultWeightedInteractionExceptionEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newWeightedInteractionException("code-978", title: "title-994")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
