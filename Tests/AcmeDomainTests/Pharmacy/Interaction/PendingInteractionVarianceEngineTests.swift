@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingInteractionVarianceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultPendingInteractionVarianceEngine()
        let item = Pharmacy.newPendingInteractionVariance("code-422", label: "label-964")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
