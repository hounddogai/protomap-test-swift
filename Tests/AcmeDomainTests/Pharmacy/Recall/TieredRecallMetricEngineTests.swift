@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyTieredRecallMetricEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultTieredRecallMetricEngine()
        let item = Pharmacy.newTieredRecallMetric("code-926", name: "name-207")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
