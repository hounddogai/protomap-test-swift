@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedDispensePolicyEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultBatchedDispensePolicyEngine()
        let item = Pharmacy.newBatchedDispensePolicy("code-298", title: "title-760")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
