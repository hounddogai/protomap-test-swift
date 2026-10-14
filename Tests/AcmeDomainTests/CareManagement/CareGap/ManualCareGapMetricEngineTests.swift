@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualCareGapMetricEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultManualCareGapMetricEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newManualCareGapMetric("code-260", name: "name-483")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
