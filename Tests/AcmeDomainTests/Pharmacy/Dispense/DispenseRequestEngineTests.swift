@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseRequestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultDispenseRequestEngine()
        let item = Pharmacy.newDispenseRequest("code-860", name: "name-622")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
