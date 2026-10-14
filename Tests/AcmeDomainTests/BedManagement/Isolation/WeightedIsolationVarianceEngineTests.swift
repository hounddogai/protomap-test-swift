@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedIsolationVarianceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultWeightedIsolationVarianceEngine()
        let item = BedManagement.newWeightedIsolationVariance("code-38", title: "title-595")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
