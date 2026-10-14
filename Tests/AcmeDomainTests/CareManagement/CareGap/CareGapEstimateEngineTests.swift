@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapEstimateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultCareGapEstimateEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newCareGapEstimate("code-638", label: "label-464")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
