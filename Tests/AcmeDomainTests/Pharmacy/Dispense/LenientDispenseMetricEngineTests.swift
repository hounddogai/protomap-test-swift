@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientDispenseMetricEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultLenientDispenseMetricEngine()
        let item = Pharmacy.newLenientDispenseMetric("code-836", name: "name-178")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
