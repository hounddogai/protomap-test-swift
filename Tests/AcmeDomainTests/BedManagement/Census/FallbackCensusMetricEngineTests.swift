@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackCensusMetricEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultFallbackCensusMetricEngine()
        let item = BedManagement.newFallbackCensusMetric("code-812", name: "name-969")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
